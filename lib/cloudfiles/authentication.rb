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
      parsed_auth_url = URI.parse(connection.auth_url)
      path = parsed_auth_url.path
      hdrhash = { "X-Auth-User" => connection.authuser, "X-Auth-Key" => connection.authkey }
      begin
        server = get_server(connection, parsed_auth_url)

        if parsed_auth_url.scheme == "https"
          server.use_ssl     = true
          server.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        server.start
      rescue Exception => e
        # uncomment if you suspect a problem with this branch of code
#         $stderr.puts "got error #{e.class}: #{e.message.inspect}\n" << e.traceback.map{|n| "\t#{n}"}.join("\n")
        raise CloudFiles::Exception::Connection, "Unable to connect to #{server.address}", caller
      end
      response = server.get(path, hdrhash)
      if (response.code =~ /^20./)
        if response["x-cdn-management-url"]
          connection.cdn_available = true
          parsed_cdn_url = URI.parse(response["x-cdn-management-url"])
          connection.cdnmgmthost   = parsed_cdn_url.host
          connection.cdnmgmtpath   = parsed_cdn_url.path
          connection.cdnmgmtport   = parsed_cdn_url.port
          connection.cdnmgmtscheme = parsed_cdn_url.scheme
        end
        parsed_storage_url = URI.parse(response["x-storage-url"])
        connection.storagehost   = set_snet(connection, parsed_storage_url.host)
        connection.storagepath   = parsed_storage_url.path
        connection.storageport   = parsed_storage_url.port
        connection.storagescheme = parsed_storage_url.scheme
        connection.authtoken     = response["x-auth-token"]
        connection.authok        = true
      else
        connection.authtoken = false
        raise CloudFiles::Exception::Authentication, "Authentication failed"
      end
      server.finish
    end

    private

      def get_server(connection, parsed_auth_url)
        Net::HTTP::Proxy(connection.proxy_host, connection.proxy_port).new(parsed_auth_url.host, parsed_auth_url.port)
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
