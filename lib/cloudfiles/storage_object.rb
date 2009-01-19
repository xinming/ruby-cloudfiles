module CloudFiles

  class StorageObject

    # Name of the object corresponding to the instantiated object
    attr_reader :name

    # Size of the object (in bytes)
    attr_reader :bytes
    
    # The parent CloudFiles::Container object
    attr_reader :container

    # Date of the object's last modification
    attr_reader :lastmodified

    # Metadata stored with the object
    attr_reader :metadata

    # MD5 hash of the object data
    attr_reader :md5sum

    # Content type of the object data
    attr_reader :content_type

    def initialize(cfclass,container,objectname) # :nodoc:
      @cfclass = cfclass
      @container = container
      @containername = container.name
      @name = objectname
      @storagehost = @cfclass.storagehost
      @storagepath = @cfclass.storagepath+"/#{@containername}/#{@name}"
      begin
        populate
      rescue NoSuchObjectException
        # The object doesn't exist yet
      end
    end

    # Caches data about the CloudFiles::StorageObject for fast retrieval.  This method is automatically called when the 
    # class is initialized, but it can be called again if the data needs to be updated.
    def populate
      response = @cfclass.cfreq("HEAD",@storagehost,@storagepath)
      raise NoSuchObjectException, "Object #{@name} does not exist" if (response.code != "204")
      @bytes = response["content-length"]
      @lastmodified = response["last-modified"]
      @md5sum = response["etag"]
      @content_type = response["content-type"]
      resphash = {}
      response.to_hash.select { |k,v| k.match(/^x-object-meta/) }.each { |x| resphash[x[0]] = x[1][0].to_s }
      @metadata = resphash
    end

    # Retrieves the data from an object and stores the data in memory.  The data is returned as a string.
    # Throws a NoSuchObjectException if the object doesn't exist.
    def data(headers = nil)
      response = @cfclass.cfreq("GET",@storagehost,@storagepath)
      raise NoSuchObjectException, "Object #{@name} does not exist" unless (response.code == "200")
      response.body.chomp
    end

    # Retrieves the data from an object and returns a stream that must be passed to a block.  Throws a 
    # NoSuchObjectException if the object doesn't exist.
    def data_stream(headers = nil,&block)
      response = @cfclass.cfreq("GET",@storagehost,@storagepath,nil,nil,&block)
      raise NoSuchObjectException, "Object #{@name} does not exist" unless (response.code == "200")
      response
    end

    # Sets the metadata for an object.  By passing a hash as an argument, you can set the metadata for an object.
    # However, setting metadata will overwrite any existing metadata for the object.
    # 
    # Throws NoSuchObjectException if the object doesn't exist.  Throws InvalidResponseException if the request
    # fails.
    def set_metadata(metadatahash)
      response = @cfclass.cfreq("POST",@storagehost,@storagepath,metadatahash)
      raise NoSuchObjectException, "Object #{@name} does not exist" if (response.code == "404")
      raise InvalidResponseException, "Invalid response code #{response.code}" unless (response.code == "202")
      populate
      true
    end
    
    # Takes supplied data and writes it to the object, saving it.  You can supply an optional list of headers, including
    # Content-Type, that will be applied to the object.
    # Updates the container cache and returns true on success, raises exceptions if stuff breaks.
    def write(data,headers=nil)
      raise SyntaxException, "No data was provided for object '#{@name}'" if (data.nil?)
      headers = { "Content-Type" => "application/octet-stream" } if (headers.nil?)
      headers["ETag"] = Digest::MD5.hexdigest(data).to_s
      response = @cfclass.cfreq("PUT",@storagehost,"#{@storagepath}",headers,data)
      raise InvalidResponseException, "Invalid content-length header sent" if (response.code == "412")
      raise MisMatchedChecksumException, "Mismatched md5sum" if (response.code == "422")
      raise InvalidResponseException, "Invalid response code #{response.code}" unless (response.code == "201")
      self.populate
      self.container.populate
      true
    end
    
    def to_s # :nodoc:
      @name
    end

  end

end