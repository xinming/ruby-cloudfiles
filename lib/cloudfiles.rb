#!/usr/bin/env ruby
# 
# == Cloud Files API
# ==== Connects Ruby Applications to Rackspace's Cloud Files service (http://www.mosso.com/cloudfiles.jsp)
# Major Hayden <major.hayden@rackspace.com>
# ----
# === License
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# === Documentation & Examples
# To begin reviewing the available methods and examples, review the documentation inside the 
# CloudFiles class.

# The CloudFiles class is the base class which holds all of the account-related functions.
# To instantiate the class and use the standard Cloud Files authentication, simply pass the
# username and API key to the class:
#   cf = CloudFiles.new("username","api_key")
# If you have an account that requires the alternative SoSo authentication, provide the
# account name when instantiating the class:
#   cf = CloudFiles.new("username","password","account_name")
# As soon as the class is instantiated, the class will attempt to authenticate with the 
# Cloud Files service. To test the result of the authentication, use the authok? boolean method.
module CloudFiles

  VERSION = '0.0.1'
  require 'net/http'
  require 'net/https'
  require 'rexml/document'
  require 'uri'
  require 'digest/md5'
  require 'jcode' 
  require 'erb'
  include ERB::Util
  
  $KCODE = 'u'

  $:.unshift(File.dirname(__FILE__))
  require 'cloudfiles/authentication'
  require 'cloudfiles/connection'
  require 'cloudfiles/container'
  require 'cloudfiles/storage_object'

end



class SyntaxException             < StandardError # :nodoc:
end
class ConnectionException         < StandardError # :nodoc:
end
class AuthenticationException     < StandardError # :nodoc:
end
class InvalidResponseException    < StandardError # :nodoc:
end
class NonEmptyContainerException  < StandardError # :nodoc:
end
class NoSuchObjectException       < StandardError # :nodoc:
end
class NoSuchContainerException    < StandardError # :nodoc:
end
class NoSuchAccountException      < StandardError # :nodoc:
end
class MisMatchedChecksumException < StandardError # :nodoc:
end
class IOException                 < StandardError # :nodoc:
end
class CDNNotEnabledException      < StandardError # :nodoc:
end