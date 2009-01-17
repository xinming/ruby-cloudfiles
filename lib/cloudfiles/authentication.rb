module CloudFiles
  class Authentication
    def initialize(connection)
      path = '/auth'
      hdrhash = { "X-Auth-User" => connection.authuser, "X-Auth-Key" => connection.authkey }
      begin
        server = Net::HTTP.new('api.mosso.com',443)
        server.use_ssl = true
        server.verify_mode = OpenSSL::SSL::VERIFY_NONE
        server.start
      rescue
        raise ConnectionException, "Unable to connect to #{server}"
      end
      response = server.get(path,hdrhash)
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
      if (response.code == "204")
        connection.cdnmgmthost = URI.parse(response["x-cdn-management-url"]).host
        connection.cdnmgmtpath = URI.parse(response["x-cdn-management-url"]).path
        connection.storagehost = URI.parse(response["x-storage-url"]).host
        connection.storagepath = URI.parse(response["x-storage-url"]).path
        connection.authtoken = response["x-auth-token"]
        connection.authok = true
      else
        connection.authtoken = false
        raise AuthenticationException, "Authentication failed"
      end
      server.finish
      true
    end
  end
end