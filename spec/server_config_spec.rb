require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

Server = CouchSpring::Server unless defined?( Server )

describe CouchSpring::ServerConfig do
  before do
    CouchSpring.clear_servers
    CouchSpring.repository = nil
    capturing_stderr do
      COUCH_ENV = nil
      COUCH_ROOT = nil
    end
  end
    
  describe 'configuration' do
    it '#servers should return an empty hash by default' do
      CouchSpring.servers.should == {}
    end
    
    it 'should create a default server if no argument is passed' do 
      server = CouchSpring.server 
      server.should_not be_nil
      CouchSpring.servers.should_not be_empty
      CouchSpring.servers[:default].should == server
    end
    
    it 'should add the default server from yaml if one is found' do
      capturing_stderr do
        COUCH_ENV = 'cloudant'
        COUCH_ROOT = File.dirname(__FILE__)
      end
      CouchSpring::Database.stub(:create!).and_return(true)

      server = CouchSpring.server
      server.uri.should == "https://kane:password@kane.cloudant.com" 
    end
    
    it 'should add a server from yaml from an environment/repository name' do
      capturing_stderr { COUCH_ROOT = File.dirname(__FILE__) }
      
      CouchSpring::Database.stub(:create!).and_return(true)
      
      server = CouchSpring.server( :production )
      server.uri.should == "https://kane:password@rubyghetto.com:5984"
    end
    
    it 'should create the database when adding a server from yaml' do
      server = CouchSpring.server( :test )
      server.databases.select{|db| db.name == 'couch_spring_test'}.should_not be_empty
    end
    
    it 'should #clear_servers' do 
      CouchSpring.clear_servers
      CouchSpring.servers.should == {}
    end  
    
    it 'should add servers when a symbol is requested that is not found as a servers key' do 
      CouchSpring.server # adds the default
      server = Server.new(:domain => 'userlandia.net')
      CouchSpring.server(:users, server)
      CouchSpring.servers.size.should == 2
      CouchSpring.servers[:users].should == server
    end
    
    it 'should not duplicate servers' do
      CouchSpring.server # adds the default
      server = Server.new(:domain => 'userlandia.net')
      CouchSpring.server(:users, server) 
      
      # repeat
      CouchSpring.server(:users, server)
      CouchSpring.servers.size.should == 2
      CouchSpring.server
      CouchSpring.servers.size.should == 2
    end    
    
    it 'should list the servers in use' do
      CouchSpring.server # adds the default
      server = Server.new(:domain => 'userlandia.net')
      CouchSpring.server(:users, server)
       
      CouchSpring.servers.each do |key, server|
        server.class.should == CouchSpring::Server
      end   
    end
    
    it 'should be indifferent to symbol string usage' do 
      CouchSpring.server
      server = Server.new(:domain => 'userlandia.new')
      CouchSpring.server(:users, server)
      
      CouchSpring.server('users').should == server
    end 
      
  end          
end    