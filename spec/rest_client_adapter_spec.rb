require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../lib/couch_spring/adapters/rest_client')

# This should be made into a shared example and generalized for other adapters

describe CouchSpring::RestClientAdapter do
  before :all do
    @adapter = CouchSpring::RestClientAdapter
  end
  
  describe 'http methods' do
    [:get, :post, :put, :delete, :copy].each do |http_method|
      it "responds to #{http_method}" do
        @adapter.respond_to?(http_method).should == true
      end
    end
  end
  
  describe 'exception handling' do
    describe 'converts errors' do
      [RestClient::ResourceNotFound, RestClient::RequestTimeout, RestClient::ServerBrokeConnection].each do |e|
        converted_e = "CouchSpring::#{e.to_s[/[^:]*$/]}".constantize
        it "#{e} to #{converted_e}" do
          RestClient.should_receive(:get).and_raise( e )
          lambda { @adapter.get('http://foo') }.should raise_error( converted_e )
        end
      end
      
      it 'detects conflicts via the exception message' do
        class FunkyError < RestClient::ResourceNotFound
          def message
            "conflict with strange class 409"
          end
        end
        
        RestClient.should_receive(:get).and_raise( FunkyError )
        lambda { @adapter.get('http://foo') }.should raise_error( CouchSpring::Conflict )
        
        class FunkyError < RestClient::ResourceNotFound
          def message
            "409 conflict"
          end
        end
        
        RestClient.should_receive(:get).and_raise( FunkyError )
        lambda { @adapter.get('http://foo') }.should raise_error( CouchSpring::Conflict )
      end
      
      it 'does not mis-recognize conflicts' do
        class FunkyError < RestClient::ResourceNotFound
          def message
            "thing not found with id 40923"
          end
        end
        
        RestClient.should_receive(:get).and_raise( FunkyError )
        lambda { @adapter.get('http://foo') }.should raise_error( CouchSpring::ResourceNotFound )
      end
      
      it 'defaults the exception class to CouchSpring::RequestFailed' do
        class UnknownError < Exception; end
        RestClient.should_receive(:get).and_raise(UnknownError)
        lambda { @adapter.get("http:://foo") }.should raise_error( CouchSpring::RequestFailed )
      end
    end
    
    describe 'message' do
      class ResponsyError < RestClient::ResourceNotFound
        def response
          "{foo:'bar'}"
        end
        
        def message
          'Messaging ... can you hear me now?'
        end
      end
      
      it 'includes the original message' do
        RestClient.should_receive(:get).and_raise(ResponsyError)
        begin
          @adapter.get("http:://foo")
        rescue Exception => e
          e.message.should include 'Messaging ... can you hear me now?'
        end
      end
      
      it 'includes the response if there is one' do
        RestClient.should_receive(:get).and_raise(ResponsyError)
        begin
          @adapter.get("http:://foo")
        rescue Exception => e
          e.message.should include "{foo:'bar'}"
        end
      end
    end
  end
end