require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
 
Server = CouchDB::Server unless defined?( Server )
describe Server do
  before(:each) do
    @server = Server.new
  end
  
  describe 'initialization' do
    it 'should have a default uri "http://127.0.0.1:5984"' do
      @server.uri.should == 'http://127.0.0.1:5984' 
    end
    
    it 'should have a settable domain' do 
      server = Server.new(:domain => 'newhost.com')
      server.uri.should == 'http://newhost.com:5984'
    end
    
    it 'should have a settable port' do
      server = Server.new(:port => '8888')
      server.uri.should == "http://127.0.0.1:8888"
      server = Server.new(:port => 5432)
      server.uri.should == "http://127.0.0.1:5432"
    end
    
    it 'should have a default uuid limit' do
      @server.uuid_limit.should == 1000
    end  
  end 
  
  it 'should be equal if the uri is the same' do
    server = Server.new
    server.uri.should == @server.uri 
    server.should == @server
  end  
  
  
  describe 'uuids' do
    it 'should have a settable limit' do
      server = Server.new(:uuid_limit => 100)
      server.uuid_limit.should == 100
    end
  
    it 'should retain a set to prevent collision' do 
      token = @server.next_uuid( 2 ) # initiates a call to the server for 2 uuids
      @server.next_uuid.should_not == token
      CouchDB.should_receive(:get).and_return({'uuids' => ['my_uuid']}) # because we have run out of uuids on the last request
      newest_token = @server.next_uuid
      newest_token.should == 'my_uuid' 
    end
    
    it 'should not show the uuids' do 
      # because it is too bloody long
      @server.inspect.should_not include('uuid')
      @server.to_s.should_not include('uuid')
    end   
  end   
  
  describe 'general managment' do
    it 'should get info' do
      CouchDB.should_receive(:get).with("#{@server.uri}/" ) 
      @server.info 
    end  
    
    it 'should restart the couchdb server' do
      CouchDB.should_receive(:post).with("#{@server.uri}/_restart" ) 
      @server.restart!
    end
    
    it 'should retrieve configuration info' do
      CouchDB.should_receive(:get).with("#{@server.uri}/_config")
      @server.config
    end
    
    it 'should retrieve stats' do
      CouchDB.should_receive(:get).with("#{@server.uri}/_stats")
      @server.stats
    end
    
    it 'should retrieve subsets of stats when passed a group and/or subgroup' do 
      CouchDB.should_receive(:get).with("#{@server.uri}/_stats/httpd/requests")
      @server.stats('httpd', 'requests')
    end        
  end
  
  describe 'managing databases' do
    before do
      @db = CouchDB::Database.new
      @db.delete
      @server.database_names.should_not include('ruby')
      @db.save
    end
    
    after do
      @db.delete 
    end  
       
    it 'should return all database names from the server' do
      @server.database_names.should include('ruby')
    end  
    
    it 'should return database instances for all the databases on the server' do 
      @server.databases.select{|db| db.name == 'ruby'}.should_not be_empty
    end  
  end   
       
end  
