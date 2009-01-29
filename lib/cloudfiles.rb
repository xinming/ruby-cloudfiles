#!/usr/bin/env ruby
# 
# == Cloud Files API
# ==== Connects Ruby Applications to Rackspace's Cloud Files service (http://www.mosso.com/cloudfiles.jsp)
# Initial work by Major Hayden <major.hayden@rackspace.com>
# Followup work by H. Wade Minter <wade.minter@rackspace.com>
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

# The CloudFiles class is the base class.  Not much of note happens here.
# To create a new CloudFiles connection, use the CloudFiles::Connection.new('user_name', 'api_key') method.
module CloudFiles

  VERSION = '0.0.1'
  require 'net/http'
  require 'net/https'
  require 'rexml/document'
  require 'uri'
  require 'digest/md5'
  require 'jcode' 
  require 'time'
  require 'erb'
  require 'rubygems'
  require 'mime/types'
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
class ObjectExistsException       < StandardError # :nodoc:
end