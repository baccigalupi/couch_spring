require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

Server = CouchDB::Server unless defined?( Server )

describe CouchDB::ServerConfig do
  before do
    CouchDB.clear_servers
  end
    
  describe 'configuration' do
    it '#servers should return an empty hash by default' do
      CouchDB.servers.should == {}
    end
    
    it 'should create a default server if no argument is passed' do 
      server = CouchDB.server 
      server.should_not be_nil
      CouchDB.servers.should_not be_empty
      CouchDB.servers[:default].should == server
    end    
    
    it 'should #clear_servers' do 
      CouchDB.clear_servers
      CouchDB.servers.should == {}
    end  
    
    it 'should add servers when a symbol is requested that is not found as a servers key' do 
      CouchDB.server # adds the default
      server = Server.new(:domain => 'userlandia.net')
      CouchDB.server(:users, server)
      CouchDB.servers.size.should == 2
      CouchDB.servers[:users].should == server
    end
    
    it 'should not duplicate servers' do
      CouchDB.server # adds the default
      server = Server.new(:domain => 'userlandia.net')
      CouchDB.server(:users, server) 
      
      # repeat
      CouchDB.server(:users, server)
      CouchDB.servers.size.should == 2
      CouchDB.server
      CouchDB.servers.size.should == 2
    end    
    
    it 'should list the servers in use' do
      CouchDB.server # adds the default
      server = Server.new(:domain => 'userlandia.net')
      CouchDB.server(:users, server)
       
      CouchDB.servers.each do |key, server|
        server.class.should == CouchDB::Server
      end   
    end
    
    it 'should be indifferent to symbol string usage' do 
      CouchDB.server
      server = Server.new(:domain => 'userlandia.new')
      CouchDB.server(:users, server)
      
      CouchDB.server('users').should == server
    end 
      
  end          
end    