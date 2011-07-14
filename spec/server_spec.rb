require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
 
Server = CouchSpring::Server unless defined?( Server )
describe Server do
  before :all do
    CouchSpring.clear_servers
    CouchSpring.repository = nil
    capturing(:stderr) { COUCH_ENV = nil }
    capturing(:stderr) { COUCH_ROOT = nil }
  end
  
  before :each do
    @server = Server.new
    @server.clear!
  end
  
  describe 'initialization' do
    it 'should have a default uri "http://127.0.0.1:5984"' do
      @server.uri.should == 'http://127.0.0.1:5984' 
    end
    
    it 'should have a settable domain' do 
      server = Server.new(:domain => 'newhost.com')
      server.uri.should == 'http://newhost.com'
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
    
    it 'should have settable protocol' do
      server = Server.new(:protocol => 'https')
      server.uri.should == "https://127.0.0.1:5984"
    end 
    
    it 'should have credentials if provided' do
      server = Server.new(:username => 'kane', :password => 'secret')
      server.uri.should == 'http://kane:secret@127.0.0.1:5984'
    end 
  end 
  
  describe 'equality' do
    it 'should be equal if the uri is the same' do
      server = Server.new
      server.uri.should == @server.uri 
      server.should == @server
    end
  end
  
  describe 'uuids' do
    it 'should have a settable limit' do
      server = Server.new(:uuid_limit => 100)
      server.uuid_limit.should == 100
    end
  
    it 'should retain a set to prevent collision' do 
      token = @server.next_uuid( 2 ) # initiates a call to the server for 2 uuids
      @server.next_uuid.should_not == token
      CouchSpring.should_receive(:get).and_return({'uuids' => ['my_uuid']}) # because we have run out of uuids on the last request
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
      CouchSpring.should_receive(:get).with("#{@server.uri}/" ) 
      @server.info 
    end  
    
    it 'should restart the couchdb server' do
      CouchSpring.should_receive(:post).with("#{@server.uri}/_restart" ) 
      @server.restart!
    end
    
    it 'should retrieve configuration info' do
      CouchSpring.should_receive(:get).with("#{@server.uri}/_config")
      @server.config
    end
    
    it 'should retrieve stats' do
      CouchSpring.should_receive(:get).with("#{@server.uri}/_stats")
      @server.stats
    end
    
    it 'should retrieve subsets of stats when passed a group and/or subgroup' do 
      CouchSpring.should_receive(:get).with("#{@server.uri}/_stats/httpd/requests")
      @server.stats('httpd', 'requests')
    end
    
    it 'should have a size' do
      @server.database('foo')
      @server.database('default')
      @server.database_names.size.should == 2
      @server.size.should == 2
    end
    
    it 'have an #empty? method that works as expected' do
      @server.size.should == 0
      @server.empty?.should == true
      @server.database('foo')
      @server.size.should == 1
      @server.empty?.should == false
    end
  end
  
  describe 'managing databases' do
    before do
      @db = CouchSpring::Database.new 
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
    
    it 'should be able to create a database with itself as the server' do
      db = @server.database('foo')
      @server.database_names.should include 'foo'
      db.server.should == @server
    end 
    
    it '#clear! should delete all databases' do
      @server.database('foo')
      @server.database_names.should include 'foo', 'ruby'
      @server.clear!
      @server.database_names.should_not include 'foo', 'ruby'
    end 
  end       
end  
