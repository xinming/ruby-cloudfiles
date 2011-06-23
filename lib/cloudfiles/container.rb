module CloudFiles
  class Container
    # See COPYING for license information.
    # Copyright (c) 2011, Rackspace US, Inc.

    # Name of the container which corresponds to the instantiated container class
    attr_reader :name

    # The parent CloudFiles::Connection object for this container
    attr_reader :connection

    # Retrieves an existing CloudFiles::Container object tied to the current CloudFiles::Connection.  If the requested
    # container does not exist, it will raise a CloudFiles::Exception::NoSuchContainer Exception.
    #
    # Will likely not be called directly, instead use connection.container('container_name') to retrieve the object.
    def initialize(connection, name)
      @connection = connection
      @name = name
      @storagehost = self.connection.storagehost
      @storagepath = self.connection.storagepath + "/" + CloudFiles.escape(@name)
      @storageport = self.connection.storageport
      @storagescheme = self.connection.storagescheme
      if self.connection.cdn_available?
        @cdnmgmthost = self.connection.cdnmgmthost
        @cdnmgmtpath = self.connection.cdnmgmtpath + "/" + CloudFiles.escape(@name) if self.connection.cdnmgmtpath
        @cdnmgmtport = self.connection.cdnmgmtport
        @cdnmgmtscheme = self.connection.cdnmgmtscheme
      end
      # Load the metadata now, so we'll get a CloudFiles::Exception::NoSuchContainer exception should the container
      # not exist.
      self.container_metadata
    end
    
    # Refreshes data about the container and populates class variables. Items are otherwise
    # loaded in a lazy loaded fashion.
    #
    #   container.count
    #   => 2
    #   [Upload new file to the container]
    #   container.count
    #   => 2
    #   container.populate
    #   container.count
    #   => 3
    def refresh
      @metadata = @cdn_metadata = nil
      true
    end
    alias :populate :refresh

    # Retrieves Metadata for the container
    def container_metadata
      @metadata ||= (
        response = self.connection.cfreq("HEAD", @storagehost, @storagepath + "/", @storageport, @storagescheme)
        raise CloudFiles::Exception::NoSuchContainer, "Container #{@name} does not exist" unless (response.code =~ /^20/)
        resphash = {}
        response.to_hash.select { |k,v| k.match(/^x-container-meta/) }.each { |x| resphash[x[0]] = x[1].to_s }
        {:bytes => response["x-container-bytes-used"].to_i, :count => response["x-container-object-count"].to_i, :metadata => resphash}
      )
    end

    # Retrieves CDN-Enabled Meta Data
    def cdn_metadata
      return @cdn_metadata if @cdn_metadata
      if cdn_available?
        @cdn_metadata = (
          response = self.connection.cfreq("HEAD", @cdnmgmthost, @cdnmgmtpath, @cdnmgmtport, @cdnmgmtscheme)
          cdn_enabled = ((response["x-cdn-enabled"] || "").downcase == "true") ? true : false
          {
            :cdn_enabled => cdn_enabled,
            :cdn_ttl => cdn_enabled ? response["x-ttl"].to_i : nil,
            :cdn_url => cdn_enabled ? response["x-cdn-uri"] : nil,
            :cdn_ssl_url => cdn_enabled ? response["x-cdn-ssl-uri"] : nil,
            :user_agent_acl => response["x-user-agent-acl"],
            :referrer_acl => response["x-referrer-acl"],
            :cdn_log => (cdn_enabled and response["x-log-retention"] == "True") ? true : false
          }
        )
      else
        @cdn_metadata = {}
      end
    end
    
    # Returns the container's metadata as a nicely formatted hash, stripping off the X-Meta-Object- prefix that the system prepends to the
    # key name.
    #
    #    object.metadata
    #    => {"ruby"=>"cool", "foo"=>"bar"}
    def metadata
      metahash = {}
      self.container_metadata[:metadata].each{ |key, value| metahash[key.gsub(/x-container-meta-/, '').gsub(/%20/, ' ')] = URI.decode(value).gsub(/\+\-/, ' ') }
      metahash
    end

    # Sets the metadata for an object.  By passing a hash as an argument, you can set the metadata for an object.
    # New calls to set metadata are additive.  To remove metadata, set the value of the key to nil.  
    #
    # Throws NoSuchObjectException if the container doesn't exist.  Throws InvalidResponseException if the request
    # fails.
    def set_metadata(metadatahash)
      headers = {}
      metadatahash.each{ |key, value| headers['X-Container-Meta-' + CloudFiles.escape(key.to_s.capitalize)] = value.to_s }
      response = self.connection.cfreq("POST", @storagehost, @storagepath, @storageport, @storagescheme, headers)
      raise CloudFiles::Exception::NoSuchObject, "Container #{@name} does not exist" if (response.code == "404")
      raise CloudFiles::Exception::InvalidResponse, "Invalid response code #{response.code}" unless (response.code =~ /^20/)
      true
    end
    
    # Size of the container (in bytes)
    def bytes
      self.container_metadata[:bytes]
    end

    # Number of objects in the container
    def count
      self.container_metadata[:count]
    end

    # Returns true if the container is public and CDN-enabled.  Returns false otherwise.
    #
    # Aliased as container.public?
    #
    #   public_container.cdn_enabled?
    #   => true
    #
    #   private_container.public?
    #   => false
    def cdn_enabled
      cdn_available? && self.cdn_metadata[:cdn_enabled]
    end
    alias :cdn_enabled? :cdn_enabled
    alias :public? :cdn_enabled

    # CDN container TTL (if container is public)
    def cdn_ttl
      self.cdn_metadata[:cdn_ttl]
    end

    # CDN container URL (if container is public)
    def cdn_url
      self.cdn_metadata[:cdn_url]
    end

    # CDN SSL container URL (if container is public)
    def cdn_ssl_url
      self.cdn_metadata[:cdn_ssl_url]
    end

    # The container ACL on the User Agent
    def user_agent_acl
      self.cdn_metadata[:user_agent_acl]
    end

    # The container ACL on the site Referrer
    def referrer_acl
      self.cdn_metadata[:referrer_acl]
    end

    # Returns true if log retention is enabled on this container, false otherwise
    def cdn_log
      self.cdn_metadata[:cdn_log]
    end
    alias :log_retention? :cdn_log
    alias :cdn_log? :cdn_log

    # Change the log retention status for this container.  Values are true or false.
    #
    # These logs will be periodically (at unpredictable intervals) compressed and uploaded
    # to a “.CDN_ACCESS_LOGS” container in the form of “container_name.YYYYMMDDHH-XXXX.gz”.
    def log_retention=(value)
      raise Exception::CDNNotAvailable unless cdn_available?
      response = self.connection.cfreq("POST", @cdnmgmthost, @cdnmgmtpath, @cdnmgmtport, @cdnmgmtscheme, {"x-log-retention" => value.to_s.capitalize})
      raise CloudFiles::Exception::InvalidResponse, "Invalid response code #{response.code}" unless (response.code == "201" or response.code == "202")
      return true
    end


    # Returns the CloudFiles::StorageObject for the named object.  Refer to the CloudFiles::StorageObject class for available
    # methods.  If the object exists, it will be returned.  If the object does not exist, a NoSuchObjectException will be thrown.
    #
    #   object = container.object('test.txt')
    #   object.data
    #   => "This is test data"
    #
    #   object = container.object('newfile.txt')
    #   => NoSuchObjectException: Object newfile.txt does not exist
    def object(objectname)
      o = CloudFiles::StorageObject.new(self, objectname, true)
      return o
    end
    alias :get_object :object


    # Gathers a list of all available objects in the current container and returns an array of object names.
    #   container = cf.container("My Container")
    #   container.objects                     #=> [ "cat", "dog", "donkey", "monkeydir", "monkeydir/capuchin"]
    # Pass a limit argument to limit the list to a number of objects:
    #   container.objects(:limit => 1)                  #=> [ "cat" ]
    # Pass an marker with or without a limit to start the list at a certain object:
    #   container.objects(:limit => 1, :marker => 'dog')                #=> [ "donkey" ]
    # Pass a prefix to search for objects that start with a certain string:
    #   container.objects(:prefix => "do")       #=> [ "dog", "donkey" ]
    # Only search within a certain pseudo-filesystem path:
    #   container.objects(:path => 'monkeydir')     #=> ["monkeydir/capuchin"]
    # Only grab "virtual directories", based on a single-character delimiter (no "directory" objects required):
    #   container.objects(:delimiter => '/')      #=> ["monkeydir"]
    # All arguments to this method are optional.
    #
    # Returns an empty array if no object exist in the container.  Throws an InvalidResponseException
    # if the request fails.
    def objects(params = {})
      params[:marker] ||= params[:offset] unless params[:offset].nil?
      query = []
      params.each do |param, value|
        if [:limit, :marker, :prefix, :path, :delimiter].include? param
          query << "#{param}=#{CloudFiles.escape(value.to_s)}"
        end
      end
      response = self.connection.cfreq("GET", @storagehost, "#{@storagepath}?#{query.join '&'}", @storageport, @storagescheme)
      return [] if (response.code == "204")
      raise CloudFiles::Exception::InvalidResponse, "Invalid response code #{response.code}" unless (response.code == "200")
      return CloudFiles.lines(response.body)
    end
    alias :list_objects :objects

    # Retrieves a list of all objects in the current container along with their size in bytes, hash, and content_type.
    # If no objects exist, an empty hash is returned.  Throws an InvalidResponseException if the request fails.  Takes a
    # parameter hash as an argument, in the same form as the objects method.
    #
    # Accepts the same options as objects to limit the returned set.
    #
    # Returns a hash in the same format as the containers_detail from the CloudFiles class.
    #
    #   container.objects_detail
    #   => {"test.txt"=>{:content_type=>"application/octet-stream",
    #                    :hash=>"e2a6fcb4771aa3509f6b27b6a97da55b",
    #                    :last_modified=>Mon Jan 19 10:43:36 -0600 2009,
    #                    :bytes=>"16"},
    #       "new.txt"=>{:content_type=>"application/octet-stream",
    #                   :hash=>"0aa820d91aed05d2ef291d324e47bc96",
    #                   :last_modified=>Wed Jan 28 10:16:26 -0600 2009,
    #                   :bytes=>"22"}
    #      }
    def objects_detail(params = {})
      params[:marker] ||= params[:offset] unless params[:offset].nil?
      query = ["format=xml"]
      params.each do |param, value|
        if [:limit, :marker, :prefix, :path, :delimiter].include? param
          query << "#{param}=#{CloudFiles.escape(value.to_s)}"
        end
      end
      response = self.connection.cfreq("GET", @storagehost, "#{@storagepath}?#{query.join '&'}", @storageport, @storagescheme)
      return {} if (response.code == "204")
      raise CloudFiles::Exception::InvalidResponse, "Invalid response code #{response.code}" unless (response.code == "200")
      doc = REXML::Document.new(response.body)
      detailhash = {}
      doc.elements.each("container/object") { |o|
        detailhash[o.elements["name"].text] = { :bytes => o.elements["bytes"].text, :hash => o.elements["hash"].text, :content_type => o.elements["content_type"].text, :last_modified => DateTime.parse(o.elements["last_modified"].text) }
      }
      doc = nil
      return detailhash
    end
    alias :list_objects_info :objects_detail

    # Returns true if a container is empty and returns false otherwise.
    #
    #   new_container.empty?
    #   => true
    #
    #   full_container.empty?
    #   => false
    def empty?
      return (container_metadata[:count].to_i == 0)? true : false
    end

    # Returns true if object exists and returns false otherwise.
    #
    #   container.object_exists?('goodfile.txt')
    #   => true
    #
    #   container.object_exists?('badfile.txt')
    #   => false
    def object_exists?(objectname)
      response = self.connection.cfreq("HEAD", @storagehost, "#{@storagepath}/#{CloudFiles.escape objectname}", @storageport, @storagescheme)
      return (response.code =~ /^20/)? true : false
    end

    # Creates a new CloudFiles::StorageObject in the current container.
    #
    # If an object with the specified name exists in the current container, that object will be returned.  Otherwise,
    # an empty new object will be returned.
    #
    # Passing in the optional make_path argument as true will create zero-byte objects to simulate a filesystem path
    # to the object, if an objectname with path separators ("/path/to/myfile.mp3") is supplied.  These path objects can
    # be used in the Container.objects method.
    def create_object(objectname, make_path = false)
      CloudFiles::StorageObject.new(self, objectname, false, make_path)
    end

    # Removes an CloudFiles::StorageObject from a container.  True is returned if the removal is successful.  Throws
    # NoSuchObjectException if the object doesn't exist.  Throws InvalidResponseException if the request fails.
    #
    #   container.delete_object('new.txt')
    #   => true
    #
    #   container.delete_object('nonexistent_file.txt')
    #   => NoSuchObjectException: Object nonexistent_file.txt does not exist
    def delete_object(objectname)
      response = self.connection.cfreq("DELETE", @storagehost, "#{@storagepath}/#{CloudFiles.escape objectname}", @storageport, @storagescheme)
      raise CloudFiles::Exception::NoSuchObject, "Object #{objectname} does not exist" if (response.code == "404")
      raise CloudFiles::Exception::InvalidResponse, "Invalid response code #{response.code}" unless (response.code =~ /^20/)
      true
    end

    # Makes a container publicly available via the Cloud Files CDN and returns true upon success.  Throws NoSuchContainerException
    # if the container doesn't exist or if the request fails.
    #
    # Takes an optional hash of options, including:
    #
    # :ttl, which is the CDN cache TTL in seconds (default 86400 seconds or 1 day, minimum 3600 or 1 hour, maximum 259200 or 3 days)
    #
    # :user_agent_acl, a Perl-compatible regular expression limiting access to this container to user agents matching the given regular expression
    #
    # :referrer_acl, a Perl-compatible regular expression limiting access to this container to HTTP referral URLs matching the given regular expression
    #
    #   container.make_public(:ttl => 8900, :user_agent_acl => "/Mozilla/", :referrer_acl => "/^http://rackspace.com")
    #   => true
    def make_public(options = {:ttl => 86400})
      raise Exception::CDNNotAvailable unless cdn_available?
      if options.is_a?(Fixnum)
        print "DEPRECATED: make_public takes a hash of options now, instead of a TTL number"
        ttl = options
        options = {:ttl => ttl}
      end

      response = self.connection.cfreq("PUT", @cdnmgmthost, @cdnmgmtpath, @cdnmgmtport, @cdnmgmtscheme)
      raise CloudFiles::Exception::NoSuchContainer, "Container #{@name} does not exist" unless (response.code == "201" || response.code == "202")

      headers = { "X-TTL" => options[:ttl].to_s , "X-CDN-Enabled" => "True" }
      headers["X-User-Agent-ACL"] = options[:user_agent_acl] if options[:user_agent_acl]
      headers["X-Referrer-ACL"] = options[:referrer_acl] if options[:referrer_acl]
      response = self.connection.cfreq("POST", @cdnmgmthost, @cdnmgmtpath, @cdnmgmtport, @cdnmgmtscheme, headers)
      raise CloudFiles::Exception::NoSuchContainer, "Container #{@name} does not exist" unless (response.code == "201" || response.code == "202")
      refresh
      true
    end
   
    # Makes a container private and returns true upon success.  Throws NoSuchContainerException
    # if the container doesn't exist or if the request fails.
    #
    # Note that if the container was previously public, it will continue to exist out on the CDN until it expires.
    #
    #   container.make_private
    #   => true
    def make_private
      raise Exception::CDNNotAvailable unless cdn_available?
      headers = { "X-CDN-Enabled" => "False" }
      response = self.connection.cfreq("POST", @cdnmgmthost, @cdnmgmtpath, @cdnmgmtport, @cdnmgmtscheme, headers)
      raise CloudFiles::Exception::NoSuchContainer, "Container #{@name} does not exist" unless (response.code == "201" || response.code == "202")
      refresh
      true
    end

    # Purges CDN Edge Cache for all objects inside of this container
    #
    # :email, An valid email address or comma seperated 
    #  list of emails to be notified once purge is complete .
    #
    #   container.purge_from_cdn
    #   => true
    #
    #  or 
    #   
    #   container.purge_from_cdn("User@domain.com")
    #   => true
    #
    #  or
    #
    #   container.purge_from_cdn("User@domain.com, User2@domain.com")
    #   => true
    def purge_from_cdn(email=nil)
      raise Exception::CDNNotAvailable unless cdn_available?
      if email
          headers = {"X-Purge-Email" => email}
          response = self.connection.cfreq("DELETE", @cdnmgmthost, @cdnmgmtpath, @cdnmgmtport, @cdnmgmtscheme, headers)
          raise CloudFiles::Exception::Connection, "Error Unable to Purge Container: #{@name}" unless (response.code > "200" && response.code < "299")
      else
          response = self.connection.cfreq("DELETE", @cdnmgmthost, @cdnmgmtpath, @cdnmgmtport, @cdnmgmtscheme)
          raise CloudFiles::Exception::Connection, "Error Unable to Purge Container: #{@name}" unless (response.code > "200" && response.code < "299")
      true
      end
    end

    def to_s # :nodoc:
      @name
    end

    def cdn_available?
      self.connection.cdn_available?
    end

  end

end
