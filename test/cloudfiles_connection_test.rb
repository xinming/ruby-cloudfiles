$:.unshift File.dirname(__FILE__)
require 'test_helper'

class CloudfilesConnectionTest < Test::Unit::TestCase
  
  def setup
    CloudFiles::Authentication.expects(:new).returns(true)
    @connection = CloudFiles::Connection.new('dummy_user', 'dummy_key')
    @connection.storagescheme = "http"
    @connection.storageport = 80
    @connection.storagehost = "test.setup.example"
    @connection.storagepath = "/dummypath/setup"
    @connection.cdnmgmthost = "test.cdn.example"
    @connection.cdnmgmtpath = "/dummycdnpath/setup"
  end
  
  def test_initialize
    assert_equal @connection.authuser, 'dummy_user'
    assert_equal @connection.authkey, 'dummy_key'
  end
  
  def test_initalize_with_hash
    CloudFiles::Authentication.expects(:new).returns(true)
    @hash_connection = CloudFiles::Connection.new(:username => 'dummy_user', :api_key => 'dummy_key')
    assert_equal @hash_connection.authuser, "dummy_user"
    assert_equal @hash_connection.authkey, "dummy_key"
  end
  
  def test_authok
    # This would normally be set in CloudFiles::Authentication
    assert_equal @connection.authok?, false
    @connection.expects(:authok?).returns(true)
    assert_equal @connection.authok?, true
  end
  
  def test_snet
    # This would normally be set in CloudFiles::Authentication
    assert_equal @connection.snet?, false
    @connection.expects(:snet?).returns(true)
    assert_equal @connection.snet?, true
  end
      
  # def test_cfreq_get
  #   build_net_http_object
  #   assert_nothing_raised do 
  #     response = @connection.cfreq("GET", "test.server.example", "/dummypath", "80", "http")
  #   end
  # end
  # 
  # def test_cfreq_post
  #   build_net_http_object
  #   assert_nothing_raised do
  #     response = @connection.cfreq("POST", "test.server.example", "/dummypath", "80", "http")
  #   end
  # end
  # 
  # def test_cfreq_put
  #   build_net_http_object
  #   assert_nothing_raised do
  #     response = @connection.cfreq("PUT", "test.server.example", "/dummypath", "80", "http")
  #   end
  # end
  # 
  # def test_cfreq_delete
  #   build_net_http_object
  #   assert_nothing_raised do
  #     response = @connection.cfreq("DELETE", "test.server.example", "/dummypath", "80", "http")
  #   end
  # end
  # 
  # def test_cfreq_with_static_data
  #   build_net_http_object
  #   assert_nothing_raised do
  #     response = @connection.cfreq("PUT", "test.server.example", "/dummypath", "80", "http", {}, "This is string data")
  #   end
  # end
  # 
  # def test_cfreq_with_stream_data
  #   build_net_http_object
  #   require 'tempfile'
  #   file = Tempfile.new("test")
  #   assert_nothing_raised do
  #     response = @connection.cfreq("PUT", "test.server.example", "/dummypath", "80", "http", {}, file)
  #   end
  # end
  # 
  # def test_cfreq_head
  #   build_net_http_object
  #   assert_nothing_raised do
  #     response = @connection.cfreq("HEAD", "test.server.example", "/dummypath", "80", "http")
  #   end
  # end

  # def test_storage_request
  #     build_net_http_object
  #     assert_nothing_raised do
  #       response = @connection.storage_request("HEAD", "dummypath")
  #     end
  #   end
  # 
  #   def test_storage_request_adds_path
  #     build_net_http_object({}, {:method => "HEAD", :path => "#{@connection.storagepath}/dummypath"})
  #     assert_nothing_raised do
  #       response = @connection.storage_request("HEAD", "dummypath")
  #     end
  #   end
  # 
  #   def test_storage_path_does_not_add_path_when_absolute
  #     build_net_http_object({}, {:method => "HEAD", :path => "/dummypath"})
  #     assert_nothing_raised do
  #       response = @connection.storage_request("HEAD", "/dummypath")
  #     end
  #   end
  # 
  #   def test_cdn_request
  #     build_net_http_object
  #     assert_nothing_raised do
  #       response = @connection.cdn_request("HEAD", "dummypath")
  #     end
  #   end
  # 
  #   def test_cdn_request_adds_path
  #     build_net_http_object({}, {:method => "HEAD", :path => "#{@connection.cdnmgmtpath}/dummypath"})
  #     assert_nothing_raised do
  #       response = @connection.cdn_request("HEAD", "dummypath")
  #     end
  #   end
  # 
  #   def test_cdn_path_does_not_add_path_when_absolute
  #     build_net_http_object({}, {:method => "HEAD", :path => "/dummypath"})
  #     assert_nothing_raised do
  #       response = @connection.cdn_request("HEAD", "/dummypath")
  #     end
  #   end
  #  
  #   def test_net_http_raises_connection_exception
  #     Net::HTTP.expects(:new).raises(CloudFiles::Exception::Connection)
  #     assert_raises(CloudFiles::Exception::Connection) do
  #       response = @connection.cfreq("GET", "test.server.example", "/dummypath", "80", "http")
  #     end
  #   end
  #   
  #   def test_net_http_raises_one_eof_exception
  #     response = {'x-cdn-management-url' => 'http://cdn.example.com/path', 'x-storage-url' => 'http://cdn.example.com/storage', 'authtoken' => 'dummy_token'}
  #     response.stubs(:code).returns('204')
  #     server = stub(:use_ssl= => true, :verify_mode= => true, :start => true, :finish => true)
  #     server.stubs(:request).raises(EOFError).then.returns(response)
  #     Net::HTTP.stubs(:new).returns(server)
  #     assert_nothing_raised do
  #       response = @connection.cfreq("GET", "test.server.example", "/dummypath", "443", "https")
  #     end
  #   end
  #   
  #   def test_net_http_raises_one_expired_token
  #     CloudFiles::Authentication.expects(:new).returns(true)
  #     response = {'x-cdn-management-url' => 'http://cdn.example.com/path', 'x-storage-url' => 'http://cdn.example.com/storage', 'authtoken' => 'dummy_token'}
  #     response.stubs(:code).returns('401').then.returns('204')
  #     server = stub(:use_ssl= => true, :verify_mode= => true, :start => true)
  #     server.stubs(:request).returns(response)
  #     Net::HTTP.stubs(:new).returns(server)
  #     assert_nothing_raised do
  #       response = @connection.cfreq("GET", "test.server.example", "/dummypath", "80", "http")
  #     end
  #   end
  #   
  #   def test_net_http_raises_continual_eof_exceptions
  #     response = {'x-cdn-management-url' => 'http://cdn.example.com/path', 'x-storage-url' => 'http://cdn.example.com/storage', 'authtoken' => 'dummy_token'}
  #     response.stubs(:code).returns('204')
  #     server = stub(:use_ssl= => true, :verify_mode= => true, :start => true)
  #     server.stubs(:finish).returns(true)
  #     server.stubs(:request).raises(EOFError)
  #     CloudFiles::Connection.any_instance.stubs(:get_info).returns({:bytes => @bytes, :count => @count})
  #     Net::HTTP.stubs(:new).returns(server)
  #     assert_raises(CloudFiles::Exception::Connection) do
  #       response = @connection.cfreq("GET", "test.server.example", "/dummypath", "80", "http")
  #     end
  #   end
    
    def test_get_info
      @connection.authok = true
      response = {'x-account-bytes-used' => '9999', 'x-account-container-count' => '5'}
      SwiftClient.stubs(:head_account).returns(response)
      @connection.get_info
      assert_equal @connection.bytes, 9999
      assert_equal @connection.count, 5
    end
    
    def test_get_info_fails
      @connection.authok = true
      SwiftClient.stubs(:head_account).raises(ClientException.new("foo", :http_status => 999))
      assert_raises(CloudFiles::Exception::InvalidResponse) do
        @connection.get_info
      end
    end
    
    def test_public_containers
      response = [nil, [{"name" => 'foo'}, {"name" => "bar"}, {"name" => "baz"}]]
      SwiftClient.stubs(:get_account).returns(response)
      public_containers = @connection.public_containers
      assert_equal public_containers.size, 3
      assert_equal public_containers.first, 'foo'
    end
    
    def test_public_containers_empty
      response = [nil, []]
      SwiftClient.stubs(:get_account).returns(response)
      public_containers = @connection.public_containers
      assert_equal public_containers.size, 0
      assert_equal public_containers.class, Array
    end
    
    def test_public_containers_exception
      SwiftClient.stubs(:get_account).raises(ClientException.new("test_public_containers_exception", :http_status => 999))
      assert_raises(CloudFiles::Exception::InvalidResponse) do
        public_containers = @connection.public_containers
      end
    end
    
    def test_delete_container
      SwiftClient.stubs(:delete_container).returns(nil)
      response = @connection.delete_container("good_container")
      assert_equal response, true
    end
    
    def test_delete_nonempty_container
      SwiftClient.stubs(:delete_container).raises(ClientException.new("test_delete_nonempty_container", :http_status => 409))
      assert_raises(CloudFiles::Exception::NonEmptyContainer) do
        response = @connection.delete_container("not_empty")
      end
    end
    
    def test_delete_unknown_container
      SwiftClient.stubs(:delete_container).raises(ClientException.new("test_delete_unknown_container", :http_status => 999))
      assert_raises(CloudFiles::Exception::NoSuchContainer) do
        response = @connection.delete_container("not_empty")
      end
    end
    
    def test_create_container
      response = [ { "content-type"=>"application/json; charset=utf-8", "x-container-object-count"=>"1", "date"=>"", "x-container-bytes-used"=>"0", "content-length"=>"0", "accept-ranges"=>"bytes", "x-trans-id"=>"foo" }, [ { "bytes"=>0, "name"=>"foo.jpg", "content_type"=>"image/jpeg", "hash"=>"foo", "last_modified"=>"" } ] ]
      CloudFiles::Container.any_instance.stubs(:container_metadata).returns(response[0])
      SwiftClient.stubs(:put_container).returns(nil)
      container = @connection.create_container('good_container')
      assert_equal container.name, 'good_container'
    end
    
    def test_create_container_with_invalid_name
      assert_raise(CloudFiles::Exception::Syntax) do
        container = @connection.create_container('a'*300)
      end
    end
    
    def test_create_container_name_filter
      assert_raises(CloudFiles::Exception::Syntax) do 
        container = @connection.create_container('this/has/bad?characters')
      end
    end
    
    def test_create_container_error
      SwiftClient.stubs(:put_container).raises(ClientException.new("test_create_container_general_error", :http_status => 999))
      assert_raise(CloudFiles::Exception::InvalidResponse) do
        container = @connection.create_container('foobar')
      end
    end
    
    def test_container_exists_true
      response = {"x-container-object-count"=>"0", "date"=>"Fri, 02 Sep 2011 20:27:15 GMT", "x-container-bytes-used"=>"0", "content-length"=>"0", "accept-ranges"=>"bytes", "x-trans-id"=>"foo"}
      SwiftClient.stubs(:head_container).returns(response)
      assert_equal @connection.container_exists?('this_container_exists'), true
    end
    
    def test_container_exists_false
      SwiftClient.stubs(:head_container).raises(ClientException.new("test_container_exists_false", :http_status => 404))
      assert_equal @connection.container_exists?('this_does_not_exist'), false
    end
    
    def test_fetch_exisiting_container
      response = [ { "content-type"=>"application/json; charset=utf-8", "x-container-object-count"=>"1", "date"=>"", "x-container-bytes-used"=>"0", "content-length"=>"0", "accept-ranges"=>"bytes", "x-trans-id"=>"foo" }, [ { "bytes"=>0, "name"=>"foo.jpg", "content_type"=>"image/jpeg", "hash"=>"foo", "last_modified"=>"" } ] ]
      CloudFiles::Container.any_instance.stubs(:container_metadata).returns(response[0])
      container = @connection.container('good_container')
      assert_equal container.name, 'good_container'
    end
    
    def test_fetch_nonexistent_container
      CloudFiles::Container.any_instance.stubs(:container_metadata).raises(CloudFiles::Exception::NoSuchContainer)
      assert_raise(CloudFiles::Exception::NoSuchContainer) do
        container = @connection.container('bad_container')
      end
    end
    
    def test_containers
      response = [nil, [{"name" => 'foo'}, {"name" => "bar"}, {"name" => "baz"}, {"name" => "boo"}]]
      SwiftClient.stubs(:get_account).returns(response)
      containers = @connection.containers
      assert_equal containers.size, 4
      assert_equal containers.first, 'foo'
    end
    
    def test_containers_with_limit
      response = [nil, [{"name" => 'foo'}]]
      SwiftClient.stubs(:get_account).returns(response)
      containers = @connection.containers(1)
      assert_equal containers.size, 1
      assert_equal containers.first, 'foo'
    end
    
    def test_containers_with_marker
      response = [nil, [{"name" => "boo"}]]
      SwiftClient.stubs(:get_account).returns(response)
      containers = @connection.containers(0, 'baz')
      assert_equal containers.size, 1
      assert_equal containers.first, 'boo'
    end
    
    def test_no_containers_yet
      response = [nil, []]
      SwiftClient.stubs(:get_account).returns(response)
      containers = @connection.containers
      assert_equal containers.size, 0
      assert_equal containers.class, Array
    end
    
    def test_containers_bad_result
      SwiftClient.stubs(:get_account).raises(ClientException.new("foo", :http_status => 999))
      assert_raises(CloudFiles::Exception::InvalidResponse) do
        containers = @connection.containers
      end
    end
    
    def test_containers_detail
      response = [nil, [{"bytes"=>"42", "name"=>"CWX", "count"=>"3"}]]
      SwiftClient.stubs(:get_account).returns(response)
      details = @connection.containers_detail
      assert_equal details['CWX'][:count], "3"
    end
    
    def test_empty_containers_detail
      response = [nil, []]
      SwiftClient.stubs(:get_account).returns(response)
      details = @connection.containers_detail
      assert_equal details, {}
    end
    
    def test_containers_detail_bad_response
      SwiftClient.stubs(:get_account).raises(ClientException.new("foo", :http_status => 999))
      assert_raises(CloudFiles::Exception::InvalidResponse) do
        details = @connection.containers_detail
      end
    end
    
  # private
  # 
  # def build_net_http_object(args={}, cfreq_expectations={})
  #   args.merge!(:code => '204') unless args[:code]
  #   args[:response] = {} unless args[:response]
  #   response = {'x-cdn-management-url' => 'http://cdn.example.com/path', 'x-storage-url' => 'http://cdn.example.com/storage', 'authtoken' => 'dummy_token'}.merge(args[:response])
  #   response.stubs(:code).returns(args[:code])
  #   response.stubs(:body).returns args[:body] || nil
  # 
  #   if !cfreq_expectations.empty?
  #     parameter_expectations = [anything(), anything(), anything(), anything(), anything(), anything(), anything(), anything()]
  #     parameter_expectations[0] = cfreq_expectations[:method] if cfreq_expectations[:method]
  #     parameter_expectations[2] = cfreq_expectations[:path] if cfreq_expectations[:path]
  #     
  #     @connection.expects(:cfreq).with(*parameter_expectations).returns(response)
  #   else  
  #     @connection.stubs(:cfreq).returns(response)
  #   end
  # 
  # end
  # 
  # def build_net_http_object_with_cfreq_expectations(args={:code => '204' }, cfreq_expectations={})
  #   build_net_http_object(args, cfreq_expectations)
  # end
end
