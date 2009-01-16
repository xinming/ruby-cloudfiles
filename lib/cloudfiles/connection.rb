module CloudFiles

  class Connection
    # Authentication account (optional) provided when the CloudFiles class was instantiated [read-only]
    attr_reader :account

    # Authentication key provided when the CloudFiles class was instantiated [read-only]
    attr_reader :authkey

    # Token returned after a successful authentication [read-only]
    attr_reader :authtoken

    # Authentication username provided when the CloudFiles class was instantiated [read-only]
    attr_reader :authuser

    # Hostname of the CDN management server [read-only]
    attr_reader :cdnmgmthost

    # Path for managing containers on the CDN management server [read-only]
    attr_reader :cdnmgmtpath

    # Array of requests that have been made so far
    attr_reader :reqlog

    # Hostname of the storage server [read-only]
    attr_reader :storagehost

    # Path for managing containers/objects on the storage server [read-only]
    attr_reader :storagepath

    def initialize(authuser,authkey,account = nil) # :nodoc:
      @authuser = authuser
      @authkey = authkey
      @account = account
      @authok = false
      @http = {}
      @reqlog = []
      (@account.nil?)? auth() : auth_soso() ;
    end

    # Returns true if the authentication was successful and returns false otherwise.
    def authok?
      @authok
    end

    # Returns a Container object that can be manipulated easily.  Throws a NoSuchContainerException if
    # the container doesn't exist.
    def container(name)
      CloudFiles::Container.new(self,name)
    end

    # Returns the cumulative size of all objects in all containers under the account.  Throws an
    # InvalidResponseException if the request fails.
    def size
      response = cfreq("HEAD",@storagehost,@storagepath)
      raise InvalidResponseException, "Unable to obtain account size" unless (response.code == "204")
      response["x-account-bytes-used"]
    end

    # Returns the amount of containers present under the account as an integer. Throws an 
    # InvalidResponseException if the request fails.
    def count
      response = cfreq("HEAD",@storagehost,@storagepath)
      raise InvalidResponseException, "Unable to obtain container count" unless (response.code == "204")
      response["x-account-container-count"]
    end

    # Gathers a list of the containers that exist for the account and returns the list of containers
    # as an array.  If no containers exist, an empty array is returned.  Throws an InvalidResponseException
    # if the request fails.
    def containers
      response = cfreq("GET",@storagehost,@storagepath)
      return [] if (response.code == "204")
      raise InvalidResponseException, "Invalid response code #{response.code}" unless (response.code == "200")
      response.body.to_a.map { |x| x.chomp }.sort
    end

    # Retrieves a list of containers on the account along with their sizes (in bytes) and counts of the objects
    # held within them.  If no containers exist, an empty hash is returned.  Throws an InvalidResponseException
    # if the request fails.
    # 
    #   cf.containers_detail              #=> { "container1" => { :size => "36543", :count => "146" }, 
    #                                           "container2" => { :size => "105943", :count => "25" } }
    def containers_detail
      response = cfreq("GET",@storagehost,"#{@storagepath}?format=xml")
      return {} if (response.code == "204")
      raise InvalidResponseException, "Invalid response code #{response.code}" unless (response.code == "200")
      doc = REXML::Document.new(response.body)
      detailhash = {}
      doc.elements.each("account/container/") { |c|
        detailhash[c.elements["name"].text] = { :size => c.elements["size"].text, :count => c.elements["count"].text  }
      }
      doc = nil
      return detailhash
    end

    # Returns true if the container exists and returns false otherwise.
    def container_exists?(containername)
      response = cfreq("HEAD",@storagehost,"#{@storagepath}/#{containername}")
      return (response.code == "204")? true : false ;
    end

    # Creates a new container and returns a container object.  Throws an InvalidResponseException if the request
    # fails.
    def container_create(containername)
      response = cfreq("PUT",@storagehost,"#{@storagepath}/#{containername}")
      raise InvalidResponseException, "Unable to create container #{containername}" unless (response.code == "201" || response.code == "202")
      CloudFiles::Container.new(self,containername)
    end

    # Deletes a container from the account.  Throws a NonEmptyContainerException if the container still contains
    # objects.  Throws a NoSuchContainerException if the container doesn't exist.
    def container_delete(containername)
      response = cfreq("DELETE",@storagehost,"#{@storagepath}/#{containername}")
      raise NonEmptyContainerException, "Container #{containername} is not empty" if (response.code == "409")
      raise NoSuchContainerException, "Container #{containername} does not exist" unless (response.code == "204")
      true
    end

    # Gathers a list of public (CDN-enabled) containers that exist for an account and returns the list of containers
    # as an array.  If no containers are public, an empty array is returned.  Throws a InvalidResponseException if
    # the request fails.
    def public_containers
      response = cfreq("GET",@cdnmgmthost,@cdnmgmtpath)
      return [] if (response.code == "204")
      raise InvalidResponseException, "Invalid response code #{response.code}" unless (response.code == "200")
      response.body.to_a.map { |x| x.chomp }
    end

    # Performs standard Cloud Files authentication.  This method is automatically called
    # by the initialize method, so it should not need to be called manually.  Upon a 
    # successful login, the authentication token and server hosts/paths will be stored.
    # The authentication result can be checked with the authok? method.
    # 
    # Returns true if the authentication was successful.  Throws an AuthenticationException if the request
    # fails.
    def auth
      hdrhash = { "X-Auth-User" => @authuser, "X-Auth-Key" => @authkey }
      response = cfreq("GET","api.mosso.com","/auth",hdrhash)
      if (response.code == "204")
        @cdnmgmthost = URI.parse(response["x-cdn-management-url"]).host
        @cdnmgmtpath = URI.parse(response["x-cdn-management-url"]).path
        @storagehost = URI.parse(response["x-storage-url"]).host
        @storagepath = URI.parse(response["x-storage-url"]).path
        @authtoken = response["x-auth-token"]
        @authok = true
      else
        @authtoken = false
        raise AuthenticationException, "Authentication failed"
      end
      true
    end

    # Peforms the alternative SoSo authentication.  Performs the same steps as auth()
    # upon completion.
    # 
    # Returns true if the authentication was successful.  Throws an AuthenticationException if the request
    # fails.
    def auth_soso
      hdrhash = { "X-Storage-User" => @authuser, "X-Storage-Pass" => @authkey }
      response = cfreq("GET","auth.clouddrive.com","/v1/#{@account}/auth",hdrhash)
      if (response.code == "204")
        @storagehost = URI.parse(response["x-storage-url"]).host
        @storagepath = URI.parse(response["x-storage-url"]).path
        @authtoken = response["x-storage-token"]
        @authok = true
      else
        @authtoken = false
        raise AuthenticationException, "Authentication failed"
      end
      true
    end

    def headerprep(headers) # :nodoc:
      headers = {} if headers.nil?
      headers["X-Auth-Token"] = @authtoken if (authok? && @account.nil?)
      headers["X-Storage-Token"] = @authtoken if (authok? && !@account.nil?)
      headers["Connection"] = "Keep-Alive"
      headers["User-Agent"] == "Major's Nifty Ruby Cloud Files API (not done yet)"
      headers.each_key { |k| headers[k] = headers[k].to_s }
      headers
    end

    def cfreq(method,server,path,headers = nil,data = nil,&block) # :nodoc:
      start = Time.now
      hdrhash = headerprep(headers)
      if (@http[server].nil?)
        begin
          @http[server] = Net::HTTP.new(server,443)
          @http[server].use_ssl = true
          @http[server].verify_mode = OpenSSL::SSL::VERIFY_NONE
          @http[server].start
        rescue
          raise ConnectionException, "Unable to connect to #{server}"
        end
      end
      path = URI.escape(path)
      response = case method
      when "GET"    then @http[server].get(path,hdrhash,&block)
      when "PUT"    then @http[server].put(path,data,hdrhash)
      when "HEAD"   then @http[server].head(path,hdrhash)
      when "POST"   then @http[server].post(path,nil,hdrhash)
      when "DELETE" then @http[server].delete(path,hdrhash)
      end
      responsetime = "%0.3f" % (Time.now - start)
      @reqlog << "#{method} ".ljust(5)+"=> #{server}#{path} => #{response.code} => #{responsetime}s"
      response
    end

  end

end