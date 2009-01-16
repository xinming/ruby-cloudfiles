module CloudFiles

  class StorageObject

    # Name of the object corresponding to the instantiated object
    attr_reader :objectname

    # Size of the object (in bytes)
    attr_reader :size

    # Date of the object's last modification
    attr_reader :lastmodified

    # Metadata stored with the object
    attr_reader :metadata

    # MD5 hash of the object data
    attr_reader :md5sum

    # Content type of the object data
    attr_reader :contenttype

    def initialize(cfclass,containername,objectname) # :nodoc:
      @cfclass = cfclass
      @containername = containername
      @objectname = objectname
      @storagehost = @cfclass.storagehost
      @storagepath = @cfclass.storagepath+"/#{@containername}/#{@objectname}"
      populate
    end

    # Populates data about the object for fast retrieval.  This method is automatically called when the 
    # class is initialized, but it can be called again if the data needs to be updated.
    def populate
      response = @cfclass.cfreq("HEAD",@storagehost,@storagepath)
      raise NoSuchObjectException, "Object #{objectname} does not exist" if (response.code != "204")
      @size = response["content-length"]
      @lastmodified = response["last-modified"]
      @md5sum = response["etag"]
      @contenttype = response["content-type"]
      resphash = {}
      response.to_hash.select { |k,v| k.match(/^x-object-meta/) }.each { |x| resphash[x[0]] = x[1][0].to_s }
      @metadata = resphash
    end

    # Retrieves the data from an object and stores the data in memory.  The data is returned as a string.
    # Throws a NoSuchObjectException if the object doesn't exist.
    def data(headers = nil)
      response = @cfclass.cfreq("GET",@storagehost,@storagepath)
      raise NoSuchObjectException, "Object #{objectname} does not exist" unless (response.code == "200")
      response.body.chomp
    end

    # Retrieves the data from an object and returns a stream that must be passed to a block.  Throws a 
    # NoSuchObjectException if the object doesn't exist.
    def data_stream(headers = nil,&block)
      response = @cfclass.cfreq("GET",@storagehost,@storagepath,nil,nil,&block)
      raise NoSuchObjectException, "Object #{objectname} does not exist" unless (response.code == "200")
      response
    end

    # Sets the metadata for an object.  By passing a hash as an argument, you can set the metadata for an object.
    # However, setting metadata will replace any existing metadata for the object.
    # 
    # Throws NoSuchObjectException if the object doesn't exist.  Throws InvalidResponseException if the request
    # fails.
    def set_metadata(metadatahash)
      response = @cfclass.cfreq("POST",@storagehost,@storagepath,metadatahash)
      raise NoSuchObjectException, "Object @objectname does not exist" if (response.code == "404")
      raise InvalidResponseException, "Invalid response code #{response.code}" unless (response.code == "202")
      populate
      true
    end

  end

end