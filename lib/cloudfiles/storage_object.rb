module CloudFiles

  class StorageObject
    
    # Name of the object corresponding to the instantiated object
    attr_reader :name

    # Size of the object (in bytes)
    attr_reader :bytes
    
    # The parent CloudFiles::Container object
    attr_reader :container

    # Date of the object's last modification
    attr_reader :last_modified

    # Metadata stored with the object
    attr_reader :metadata

    # ETag of the object data
    attr_reader :etag

    # Content type of the object data
    attr_reader :content_type

    # Builds a new CloudFiles::StorageObject in the current container.  If force_exist is set, the object must exist or a
    # NoSuchObjectException will be raised.  If not, an "empty" CloudFiles::StorageObject will be returned, ready for data
    # via CloudFiles::StorageObject.write
    def initialize(container,objectname) 
      @container = container
      @containername = container.name
      @name = objectname
      @storagehost = self.container.connection.storagehost
      @storagepath = self.container.connection.storagepath+"/#{@containername}/#{@name}"
      if container.object_exists?(objectname)
        populate
      end
    end
    
    # Caches data about the CloudFiles::StorageObject for fast retrieval.  This method is automatically called when the 
    # class is initialized, but it can be called again if the data needs to be updated.
    def populate
      response = self.container.connection.cfreq("HEAD",@storagehost,@storagepath)
      raise NoSuchObjectException, "Object #{@name} does not exist" if (response.code != "204")
      @bytes = response["content-length"]
      @last_modified = Time.parse(response["last-modified"])
      @etag = response["etag"]
      @content_type = response["content-type"]
      resphash = {}
      response.to_hash.select { |k,v| k.match(/^x-object-meta/) }.each { |x| resphash[x[0]] = x[1][0].to_s }
      @metadata = resphash
    end

    # Retrieves the data from an object and stores the data in memory.  The data is returned as a string.
    # Throws a NoSuchObjectException if the object doesn't exist.
    def data(headers = nil)
      response = self.container.connection.cfreq("GET",@storagehost,@storagepath)
      raise NoSuchObjectException, "Object #{@name} does not exist" unless (response.code == "200")
      response.body.chomp
    end

    # Retrieves the data from an object and returns a stream that must be passed to a block.  Throws a 
    # NoSuchObjectException if the object doesn't exist.
    #def data_stream(headers = {},&block)
    #  response = self.container.connection.cfreq("GET",@storagehost,@storagepath,headers,nil,&block)
    #  raise NoSuchObjectException, "Object #{@name} does not exist" unless (response.code == "200")
    #  response
    #end

    # Sets the metadata for an object.  By passing a hash as an argument, you can set the metadata for an object.
    # However, setting metadata will overwrite any existing metadata for the object.
    # 
    # Throws NoSuchObjectException if the object doesn't exist.  Throws InvalidResponseException if the request
    # fails.
    def set_metadata(metadatahash)
      response = self.container.connection.cfreq("POST",@storagehost,@storagepath,metadatahash)
      raise NoSuchObjectException, "Object #{@name} does not exist" if (response.code == "404")
      raise InvalidResponseException, "Invalid response code #{response.code}" unless (response.code == "202")
      true
    end
    
    # Takes supplied data and writes it to the object, saving it.  You can supply an optional hash of headers, including
    # Content-Type and ETag, that will be applied to the object.
    #
    # If you would rather stream the data in chunks, instead of reading it all into memory at once, you can pass an 
    # IO object for the data, such as: object.write(open('/path/to/file.mp3'))
    #
    # You can compute your own MD5 sum and send it in the "ETag" header.  If you provide yours, it will be compared to
    # the MD5 sum on the server side.  If they do not match, the server will return a 422 status code and a MisMatchedChecksumException
    # will be raised.  If you do not provide an MD5 sum as the ETag, one will be computed on the server side.
    #
    # Updates the container cache and returns true on success, raises exceptions if stuff breaks.
    def write(data=nil,headers={})
      raise SyntaxException, "No data was provided for object '#{@name}'" if (data.nil?)
      # Try to get the content type
      if headers['Content-Type'].nil?
        if type = MIME::Types.type_for(self.name).first.nil?
          headers['Content-Type'] = "application/octet-stream"
        else
          headers['Content-Type'] = type.to_s
        end
      end
      response = self.container.connection.cfreq("PUT",@storagehost,"#{@storagepath}",headers,data)
      raise InvalidResponseException, "Invalid content-length header sent" if (response.code == "412")
      raise MisMatchedChecksumException, "Mismatched etag" if (response.code == "422")
      raise InvalidResponseException, "Invalid response code #{response.code}" unless (response.code == "201")
      self.populate
      true
    end
    
    # If the parent container is public (CDN-enabled), returns the CDN URL to this object.  Otherwise, return nil
    def public_url
      self.container.public? ? self.container.cdn_url + "/#{ERB::Util.url_encode(self.name)}" : nil
    end
    
    def to_s # :nodoc:
      @name
    end

  end

end