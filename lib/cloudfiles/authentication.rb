module CloudFiles
  class Authentication
    # See COPYING for license information.
    # Copyright (c) 2011, Rackspace US, Inc.

    # Performs an authentication to the Cloud Files servers.  Opens a new HTTP connection to the API server,
    # sends the credentials, and looks for a successful authentication.  If it succeeds, it sets the cdmmgmthost,
    # cdmmgmtpath, storagehost, storagepath, authtoken, and authok variables on the connection.  If it fails, it raises
    # an CloudFiles::Exception::Authentication exception.
    #
    # Should probably never be called directly.
    def initialize(connection)
      request = Typhoeus::Request.new(connection.auth_url,
        :method => :get,
        :headers => { "X-Auth-User" => connection.authuser, "X-Auth-Key" => connection.authkey },
        :disable_ssl_peer_verification => true,
        :verbose => ENV['CLOUDFILES_VERBOSE'] ? true : false)
      CloudFiles.hydra.queue(request)
      CloudFiles.hydra.run
      response = request.response
      headers = response.headers_hash
      if (response.code.to_s =~ /^20./)
        if headers["x-cdn-management-url"]
          connection.cdn_available = true
          connection.cdnmgmthost   = URI.parse(headers["x-cdn-management-url"]).host
          connection.cdnmgmtpath   = URI.parse(headers["x-cdn-management-url"]).path
          connection.cdnmgmtport   = URI.parse(headers["x-cdn-management-url"]).port
          connection.cdnmgmtscheme = URI.parse(headers["x-cdn-management-url"]).scheme
        end
        connection.storagehost   = set_snet(connection, URI.parse(headers["x-storage-url"]).host)
        connection.storagepath   = URI.parse(headers["x-storage-url"]).path
        connection.storageport   = URI.parse(headers["x-storage-url"]).port
        connection.storagescheme = URI.parse(headers["x-storage-url"]).scheme
        connection.authtoken     = headers["x-auth-token"]
        connection.authok        = true
      else
        connection.authtoken = false
        raise CloudFiles::Exception::Authentication, "Authentication failed"
      end
    end

    private

      def get_server(connection, parsed_auth_url)
        Typhoeus::Request.new(parsed_auth_url.host, parsed_auth_url.port)
      end

      def set_snet(connection, hostname)
        if connection.snet?
          "snet-#{hostname}"
        else
          hostname
        end
      end
  end
end
