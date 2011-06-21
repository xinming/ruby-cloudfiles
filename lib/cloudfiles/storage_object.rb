module CloudFiles
  class StorageObject
    # See COPYING for license information.
    # Copyright (c) 2011, Rackspace US, Inc.

    # Name of the object corresponding to the instantiated object
    attr_reader :name
    
    # The parent CloudFiles::Container object
    attr_reader :container

    # Builds a new CloudFiles::StorageObject in the current container.  If force_exist is set, the object must exist or a
    # CloudFiles::Exception::NoSuchObject Exception will be raised.  If not, an "empty" CloudFiles::StorageObject will be returned, ready for data
    # via CloudFiles::StorageObject.write
    def initialize(container, objectname, force_exists = false, make_path = false)
      @container = container
      @containername = container.name
      @name = objectname
      @make_path = make_path
      @storagehost = self.container.connection.storagehost
      @storagepath = self.container.connection.storagepath + "/#{CloudFiles.escape @containername}/#{CloudFiles.escape @name, '/'}"
      @storageport = self.container.connection.storageport
      @storagescheme = self.container.connection.storagescheme
      if self.container.connection.cdn_available?
        @cdnmgmthost = self.container.connection.cdnmgmthost
        @cdnmgmtpath = self.container.connection.cdnmgmtpath + "/#{CloudFiles.escape @containername}/#{CloudFiles.escape @name, '/'}"
        @cdnmgmtport = self.container.connection.cdnmgmtport
        @cdnmgmtscheme = self.container.connection.cdnmgmtscheme
      end
      if force_exists
        raise CloudFiles::Exception::NoSuchObject, "Object #{@name} does not exist" unless container.object_exists?(objectname)
      end
    end

    # Refreshes the object metadata
    def refresh
      @object_metadata = nil
      true
    end
    alias :populate :refresh

    # Retrieves Metadata for the object
    def object_metadata
      @object_metadata ||= (
        response = self.container.connection.cfreq("HEAD", @storagehost, @storagepath, @storageport, @storagescheme)
        raise CloudFiles::Exception::NoSuchObject, "Object #{@name} does not exist" unless (response.code =~ /^20/)
        resphash = {}
        response.to_hash.select { |k,v| k.match(/^x-object-meta/) }.each { |x| resphash[x[0]] = x[1].to_s }
        {
          :manifest => response["x-object-manifest"],
          :bytes => response["content-length"],
          :last_modified => Time.parse(response["last-modified"]),
          :etag => response["etag"],
          :content_type => response["content-type"],
          :metadata => resphash
        }
      )
    end

    # Size of the object (in bytes)
    def bytes
      self.object_metadata[:bytes]
    end

    # Date of the object's last modification
    def last_modified
      self.object_metadata[:last_modified]
    end

    # ETag of the object data
    def etag
      self.object_metadata[:etag]
    end

    # Content type of the object data
    def content_type
      self.object_metadata[:content_type]
    end

    def content_type=(type)
      self.copy(:headers => {'Content-Type' => type})
    end
 
    # Retrieves the data from an object and stores the data in memory.  The data is returned as a string.
    # Throws a NoSuchObjectException if the object doesn't exist.
    #
    # If the optional size and range arguments are provided, the call will return the number of bytes provided by
    # size, starting from the offset provided in offset.
    #
    #   object.data
    #   => "This is the text stored in the file"
    def data(size = -1, offset = 0, headers = {})
      if size.to_i > 0
        range = sprintf("bytes=%d-%d", offset.to_i, (offset.to_i + size.to_i) - 1)
        headers['Range'] = range
      end
      response = self.container.connection.cfreq("GET", @storagehost, @storagepath, @storageport, @storagescheme, headers)
      raise CloudFiles::Exception::NoSuchObject, "Object #{@name} does not exist" unless (response.code =~ /^20/)
      response.body
    end
    alias :read :data

    # Retrieves the data from an object and returns a stream that must be passed to a block.  Throws a
    # NoSuchObjectException if the object doesn't exist.
    #
    # If the optional size and range arguments are provided, the call will return the number of bytes provided by
    # size, starting from the offset provided in offset.
    #
    #   data = ""
    #   object.data_stream do |chunk|
    #     data += chunk
    #   end
    #
    #   data
    #   => "This is the text stored in the file"
    def data_stream(size = -1, offset = 0, headers = {}, &block)
      if size.to_i > 0
        range = sprintf("bytes=%d-%d", offset.to_i, (offset.to_i + size.to_i) - 1)
        headers['Range'] = range
      end
      self.container.connection.cfreq("GET", @storagehost, @storagepath, @storageport, @storagescheme, headers, nil) do |response|
        raise CloudFiles::Exception::NoSuchObject, "Object #{@name} does not exist. Response code #{response.code}" unless (response.code =~ /^20./)
        response.read_body(&block)
      end
    end

    # Returns the object's metadata as a nicely formatted hash, stripping off the X-Meta-Object- prefix that the system prepends to the
    # key name.
    #
    #    object.metadata
    #    => {"ruby"=>"cool", "foo"=>"bar"}
    def metadata
      metahash = {}
      self.object_metadata[:metadata].each{ |key, value| metahash[key.gsub(/x-object-meta-/, '').gsub(/\+\-/, ' ')] = URI.decode(value).gsub(/\+\-/, ' ') }
      metahash
    end

    # Sets the metadata for an object.  By passing a hash as an argument, you can set the metadata for an object.
    # However, setting metadata will overwrite any existing metadata for the object.
    #
    # Throws NoSuchObjectException if the object doesn't exist.  Throws InvalidResponseException if the request
    # fails.
    def set_metadata(metadatahash)
      headers = {}
      metadatahash.each{ |key, value| headers['X-Object-Meta-' + key.to_s.capitalize] = value.to_s }
      response = self.container.connection.cfreq("POST", @storagehost, @storagepath, @storageport, @storagescheme, headers)
      raise CloudFiles::Exception::NoSuchObject, "Object #{@name} does not exist" if (response.code == "404")
      raise CloudFiles::Exception::InvalidResponse, "Invalid response code #{response.code}" unless (response.code =~ /^20/)
      true
    end
    alias :metadata= :set_metadata
    

    # Returns the object's manifest.
    #
    #    object.manifest
    #    => "container/prefix"
    def manifest
      self.object_metadata[:manifest]
    end


    # Sets the manifest for an object.  By passing a string as an argument, you can set the manifest for an object.
    # However, setting manifest will overwrite any existing manifest for the object.
    #
    # Throws NoSuchObjectException if the object doesn't exist.  Throws InvalidResponseException if the request
    # fails.
    def set_manifest(manifest)
      headers = {'X-Object-Manifest' => manifest}
      response = self.container.connection.cfreq("PUT", @storagehost, @storagepath, @storageport, @storagescheme, headers)
      raise CloudFiles::Exception::NoSuchObject, "Object #{@name} does not exist" if (response.code == "404")
      raise CloudFiles::Exception::InvalidResponse, "Invalid response code #{response.code}" unless (response.code =~ /^20/)
      true
    end


    # Takes supplied data and writes it to the object, saving it.  You can supply an optional hash of headers, including
    # Content-Type and ETag, that will be applied to the object.
    #
    # If you would rather stream the data in chunks, instead of reading it all into memory at once, you can pass an
    # IO object for the data, such as: object.write(open('/path/to/file.mp3'))
    #
    # You can compute your own MD5 sum and send it in the "ETag" header.  If you provide yours, it will be compared to
    # the MD5 sum on the server side.  If they do not match, the server will return a 422 status code and a CloudFiles::Exception::MisMatchedChecksum Exception
    # will be raised.  If you do not provide an MD5 sum as the ETag, one will be computed on the server side.
    #
    # Updates the container cache and returns true on success, raises exceptions if stuff breaks.
    #
    #   object = container.create_object("newfile.txt")
    #
    #   object.write("This is new data")
    #   => true
    #
    #   object.data
    #   => "This is new data"
    #
    # If you are passing your data in via STDIN, just do an
    #
    #   object.write
    #
    # with no data (or, if you need to pass headers)
    #
    #  object.write(nil,{'header' => 'value})

    def write(data = nil, headers = {})
      raise CloudFiles::Exception::Syntax, "No data or header updates supplied" if ((data.nil? && $stdin.tty?) and headers.empty?)
      if headers['Content-Type'].nil?
        type = MIME::Types.type_for(self.name).first.to_s
        if type.empty?
          headers['Content-Type'] = "application/octet-stream"
        else
          headers['Content-Type'] = type
        end
      end
      # If we're taking data from standard input, send that IO object to cfreq
      data = $stdin if (data.nil? && $stdin.tty? == false)
      response = self.container.connection.cfreq("PUT", @storagehost, "#{@storagepath}", @storageport, @storagescheme, headers, data)
      code = response.code
      raise CloudFiles::Exception::InvalidResponse, "Invalid content-length header sent" if (code == "412")
      raise CloudFiles::Exception::MisMatchedChecksum, "Mismatched etag" if (code == "422")
      raise CloudFiles::Exception::InvalidResponse, "Invalid response code #{code}" unless (code =~ /^20./)
      make_path(File.dirname(self.name)) if @make_path == true
      self.refresh
      true
    end
    # Purges CDN Edge Cache for all objects inside of this container
    # 
    # :email, An valid email address or comma seperated 
    # list of emails to be notified once purge is complete .
    #
    #    obj.purge_from_cdn
    #    => true
    #
    #  or 
    #                                     
    #   obj.purge_from_cdn("User@domain.com")
    #   => true
    #                                                
    #  or
    #                                                         
    #   obj.purge_from_cdn("User@domain.com, User2@domain.com")
    #   => true
    def purge_from_cdn(email=nil)
      raise Exception::CDNNotAvailable unless cdn_available?
      if email
          headers = {"X-Purge-Email" => email}
          response = self.container.connection.cfreq("DELETE", @cdnmgmthost, @cdnmgmtpath, @cdnmgmtport, @cdnmgmtscheme, headers)
          raise CloudFiles::Exception::Connection, "Error Unable to Purge Object: #{@name}" unless (response.code.to_s =~ /^20.$/)
      else
          response = self.container.connection.cfreq("DELETE", @cdnmgmthost, @cdnmgmtpath, @cdnmgmtport, @cdnmgmtscheme)
          raise CloudFiles::Exception::Connection, "Error Unable to Purge Object: #{@name}" unless (response.code.to_s =~ /^20.$/)
      end
      true
    end

    # A convenience method to stream data into an object from a local file (or anything that can be loaded by Ruby's open method)
    #
    # You can provide an optional hash of headers, in case you want to do something like set the Content-Type manually.
    #
    # Throws an Errno::ENOENT if the file cannot be read.
    #
    #   object.data
    #   => "This is my data"
    #
    #   object.load_from_filename("/tmp/file.txt")
    #   => true
    #
    #   object.load_from_filename("/home/rackspace/myfile.tmp", 'Content-Type' => 'text/plain')
    #
    #   object.data
    #   => "This data was in the file /tmp/file.txt"
    #
    #   object.load_from_filename("/tmp/nonexistent.txt")
    #   => Errno::ENOENT: No such file or directory - /tmp/nonexistent.txt
    def load_from_filename(filename, headers = {}, check_md5 = false)
      f = open(filename)
      if check_md5
          require 'digest/md5'
          md5_hash = Digest::MD5.file(filename)
          headers["Etag"] = md5_hash.to_s()
      end
      self.write(f, headers)
      f.close
      true
    end

    # A convenience method to stream data from an object into a local file
    #
    # Throws an Errno::ENOENT if the file cannot be opened for writing due to a path error,
    # and Errno::EACCES if the file cannot be opened for writing due to permissions.
    #
    #   object.data
    #   => "This is my data"
    #
    #   object.save_to_filename("/tmp/file.txt")
    #   => true
    #
    #   $ cat /tmp/file.txt
    #   "This is my data"
    #
    #   object.save_to_filename("/tmp/owned_by_root.txt")
    #   => Errno::EACCES: Permission denied - /tmp/owned_by_root.txt
    def save_to_filename(filename)
      File.open(filename, 'wb+') do |f|
        self.data_stream do |chunk|
          f.write chunk
        end
      end
      true
    end

    # If the parent container is public (CDN-enabled), returns the CDN URL to this object.  Otherwise, return nil
    #
    #   public_object.public_url
    #   => "http://c0001234.cdn.cloudfiles.rackspacecloud.com/myfile.jpg"
    #
    #   private_object.public_url
    #   => nil
    def public_url
      self.container.public? ? self.container.cdn_url + "/#{CloudFiles.escape @name, '/'}" : nil
    end

        # If the parent container is public (CDN-enabled), returns the SSL CDN URL to this object.  Otherwise, return nil
    #
    #   public_object.public_ssl_url
    #   => "https://c61.ssl.cf0.rackcdn.com/myfile.jpg"
    #
    #   private_object.public_ssl_url
    #   => nil
    def public_ssl_url
      self.container.public? ? self.container.cdn_ssl_url + "/#{CloudFiles.escape @name, '/'}" : nil
    end

    
    # Copy this object to a new location (optionally in a new container)
    #
    # You must supply either a name for the new object or a container name, or both. If a :name is supplied without a :container, 
    # the object is copied within the current container. If the :container is specified with no :name, then the object is copied
    # to the new container with its current name.
    #
    #    object.copy(:name => "images/funny/lolcat.jpg", :container => "pictures")
    #
    # You may also supply a hash of headers in the :headers option. From there, you can set things like Content-Type, or other
    # headers as available in the API document.
    #
    #    object.copy(:name => 'newfile.tmp', :headers => {'Content-Type' => 'text/plain'})
    #
    # Returns the new CloudFiles::StorageObject for the copied item.
    def copy(options = {})
      raise CloudFiles::Exception::Syntax, "You must provide the :container, :name, or :headers for this operation" unless (options[:container] || options[:name] || options[:headers])
      new_container = options[:container] || self.container.name
      new_name = options[:name] || self.name
      new_headers = options[:headers] || {}
      raise CloudFiles::Exception::Syntax, "The :headers option must be a hash" unless new_headers.is_a?(Hash)
      new_name.sub!(/^\//,'')
      headers = {'X-Copy-From' => "#{self.container.name}/#{self.name}", 'Content-Type' => self.content_type.sub(/;.+/, '')}.merge(new_headers)
      # , 'Content-Type' => self.content_type
      new_path = self.container.connection.storagepath + "/#{CloudFiles.escape new_container}/#{CloudFiles.escape new_name, '/'}"
      response = self.container.connection.cfreq("PUT", @storagehost, new_path, @storageport, @storagescheme, headers)
      code = response.code
      raise CloudFiles::Exception::InvalidResponse, "Invalid response code #{response.code}" unless (response.code =~ /^20/)
      return CloudFiles::Container.new(self.container.connection, new_container).object(new_name)
    end
    
    # Takes the same options as the copy method, only it does a copy followed by a delete on the original object.
    #
    # Returns the new CloudFiles::StorageObject for the moved item. You should not attempt to use the old object after doing
    # a move.
    def move(options = {})
      new_object = self.copy(options)
      self.container.delete_object(self.name)
      self.freeze
      return new_object
    end
      

    def to_s # :nodoc:
      @name
    end

    private

      def cdn_available?
        @cdn_available ||= self.container.connection.cdn_available?
      end

      def make_path(path) # :nodoc:
        if path == "." || path == "/"
          return
        else
          unless self.container.object_exists?(path)
            o = self.container.create_object(path)
            o.write(nil, {'Content-Type' => 'application/directory'})
          end
          make_path(File.dirname(path))
        end
      end

  end

end
