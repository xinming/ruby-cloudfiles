#!/usr/bin/env ruby
require '../lib/cloudfiles'

username = "XXXXXXXX"
apikey = "XXXXXXXXXX"

def assert_test(testtext,bool)
  booltext = (bool)? " PASS" : "*FAIL*" ;
  (testtext+"... ").ljust(50)+booltext
end

# Test initial connection
cf = CloudFiles::Connection.new(username,apikey)
puts assert_test("Connecting to CloudFiles",cf.class == CloudFiles::Connection)

# Test container creation
testingcontainer = "CloudFiles Ruby API Testing Container"
cntnr = cf.container_create(testingcontainer)
puts assert_test("Creating test container",cntnr.class == CloudFiles::Container)

# Checking container size
size = cntnr.size.to_i
puts assert_test("  Checking container size",size == 0)

# Checking container count
count = cntnr.count.to_i
puts assert_test("  Checking container count",count == 0)

# Add a file to the container - standard method
cloudfilesfilesize = File.read("../lib/cloudfiles.rb").length
cloudfilesmd5 = Digest::MD5.hexdigest(File.read("../lib/cloudfiles.rb"))
headers = { "ETag" => cloudfilesmd5, "Content-Type" => "text/ruby", "X-Object-Meta-Testmeta" => "value" }
myobj = cntnr.object_create("cloudfiles-standard.rb",File.read("../lib/cloudfiles.rb"),headers)
puts assert_test("    Uploading object (read into memory)",myobj.class == CloudFiles::StorageObject)

# Check if object exists
bool = cntnr.object_exists?("cloudfiles-standard.rb")
puts assert_test("    Checking for object existence",bool)

# Checking container size
size = cntnr.size.to_i
puts assert_test("  Checking container size",size == cloudfilesfilesize)

# Checking container count
count = cntnr.count.to_i
puts assert_test("  Checking container count",count == 1)

# Add a file to the container - stream method
headers = { "ETag" => cloudfilesmd5, "Content-Type" => "text/ruby", "X-Object-Meta-Testmeta" => "value" }
f = IO.read("../lib/cloudfiles.rb")
myobj = cntnr.object_create("cloudfiles-stream.rb",File.read("../lib/cloudfiles.rb"),headers)
puts assert_test("    Uploading object (read from stream)",myobj.class == CloudFiles::StorageObject)

# Check if object exists
bool = cntnr.object_exists?("cloudfiles-stream.rb")
puts assert_test("    Checking for object existence",bool)

# Checking container size
size = cntnr.size.to_i
puts assert_test("  Checking container size",size == (cloudfilesfilesize*2))

# Checking container count
count = cntnr.count.to_i
puts assert_test("  Checking container count",count == 2)

# Check file size
size = myobj.size.to_i
puts assert_test("    Checking object size",size == cloudfilesfilesize)

# Check content type
contenttype = myobj.contenttype
puts assert_test("    Checking object content type",contenttype == "text/ruby")

# Check metadata
metadata = myobj.metadata
puts assert_test("    Checking object metadata",metadata["x-object-meta-testmeta"] == "value")

# Set new metadata
bool = myobj.set_metadata({ "x-object-meta-testmeta2" => "differentvalue"})
puts assert_test("    Setting new object metadata",bool)

# Check new metadata
metadata = myobj.metadata
puts assert_test("    Checking new object metadata",metadata["x-object-meta-testmeta2"] == "differentvalue")

# Get data via standard method
data = myobj.data
puts assert_test("    Retrieving object data (read into memory)",Digest::MD5.hexdigest(data) == cloudfilesmd5)

# Get data via stream
data = ""
myobj.data_stream { |chunk|
  data += chunk
}
puts assert_test("    Retrieving object data (read from stream)",Digest::MD5.hexdigest(data) == cloudfilesmd5)

# Check md5sum
md5sum = myobj.md5sum
puts assert_test("    Checking object's md5sum",md5sum == cloudfilesmd5)

# Make container public
bool = cntnr.make_public
puts assert_test("  Making container public",bool)

# Verify that container is public
bool = cntnr.public?
puts assert_test("  Verifying container is public",bool)

# Getting CDN URL
cdnurl = cntnr.cdn_url
puts assert_test("  Getting CDN URL",cdnurl)

# Setting CDN URL
bool = cntnr.set_ttl(7200)
puts assert_test("  Setting CDN TTL",bool)

# Make container private
bool = cntnr.make_private
puts assert_test("  Making container private",bool)

# Check if container is empty
bool = cntnr.empty?
puts assert_test("  Checking if container empty",bool == false)

# Remove standard object
bool = cntnr.object_delete("cloudfiles-standard.rb")
puts assert_test("    Deleting first object",bool)

# Remove stream object
bool = cntnr.object_delete("cloudfiles-stream.rb")
puts assert_test("    Deleting second object",bool)

# Check if container is empty
bool = cntnr.empty?
puts assert_test("  Checking if container empty",bool)

# Remove testing container
bool = cf.container_delete(testingcontainer)
puts assert_test("Removing container",bool)

# Check to see if container exists
bool = cf.container_exists?(testingcontainer)
puts assert_test("Checking container existence",bool == false)



