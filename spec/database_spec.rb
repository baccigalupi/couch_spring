require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
 
Server = CouchDB::Server unless defined?( Server )
Database = CouchDB::Database unless defined?( Database )

describe Database do 
  before(:each) do 
    @opts = {:name => 'things'}
    @db = Database.new(@opts) 
    CouchDB.delete( @db.uri ) rescue nil
  end
  
  describe 'initialization' do
    describe 'name' do
      it 'should not require name for initialization' do
        lambda{ Database.new }.should_not raise_error( ArgumentError )
      end 
      
      it 'should have a default name of "ruby"' do
        database = Database.new 
        database.name.should == 'ruby'
      end  
    
      it 'should escape the name, when one is provided' do
        db = Database.new(:name => '&not::kosher*%/')
        db.name.should == 'not__kosher'
      end
      
      it 'should accept Symbols as names' do
        db = Database.new( :name => :my_name )
        db.name.should == 'my_name'
      end    
    end
    
    describe 'server' do
      it 'should have the default server if none is specified' do
        db = Database.new
        db.server.should_not be_nil
        db.server.should == CouchDB.server
      end  
      
      it 'should accepts a symbol or string as the server parameter and maps it to a saved server' do
        user_server = Server.new(:port => 8888)
        CouchDB.server(:user, user_server)
        
        db = Database.new(:server => :user)
        db.server.should == user_server 
        
        db = Database.new(:server => 'user')
        db.server.should == user_server
      end  
      
      it 'accept a Server object as the server parameter' do 
        user_server = Server.new(:port => 8888)
        db = Database.new(:name => 'new_people', :server => user_server )
        db.server.should == user_server
      end   
    end 
  end
  
  describe 'uri' do
    it 'should use the default server and default database name' do
      db = Database.new
      db.name.should == 'ruby'
      db.uri.should == "http://127.0.0.1:5984/ruby"
    end
    
    it 'should use the name when provided' do
      db = Database.new( :name => 'things')
      db.name.should == 'things'
      db.uri.should == 'http://127.0.0.1:5984/things'
    end
    
    it 'should use the server when provided' do
      server = Server.new(:port => 8888)
      db = Database.new(:name => 'things', :server => server )
      db.uri.should == 'http://127.0.0.1:8888/things'
    end
  end  

  describe 'save' do
    it 'should assure that a database instance has a database on the server' do
      lambda{ CouchDB.get( @db.uri ) }.should raise_error
      @db.save
      lambda{ CouchDB.get( @db.uri ) }.should_not raise_error
    end
    
    it 'should return false when the request fails' do
      CouchDB.should_receive(:put).and_raise( CouchDB::RequestFailed )
      @db.save.should == false
    end  
    
    it 'should throw an exception when the ! form is used' do
      CouchDB.should_receive(:put).and_raise( CouchDB::RequestFailed )
      lambda{ @db.save!}.should raise_error
    end    
  end  
  
  describe '#create' do
    before(:each) do
      CouchDB.delete( @db.uri ) rescue nil
    end  
  
    it 'should generate a couchdb database for this instance if it doesn\'t yet exist' do 
      db = Database.create(@opts)
      lambda{ CouchDB.get db.uri }.should_not raise_error
    end
    
    it 'should not return false if the database already exists' do
      db = Database.create(@opts)
      db = Database.create(@opts)
      db.should_not be( false ) 
    end
  
    it 'should return false if an HTTP error occurs' do
      CouchDB.should_receive(:put).and_raise( CouchDB::RequestFailed )
      db = Database.create(@opts)
      db.should == false
    end 
  end
  
  describe '#create!' do  
    it 'should create and return a couchdb database if it doesn\'t yet exist' do
      lambda{ CouchDB.get db.uri }.should raise_error
      db = Database.create!(@opts)
      lambda{ CouchDB.get db.uri }.should_not raise_error
    end
  
    it 'create! should not raise an error if the database already exists' do 
      Database.create(@opts) 
      lambda{ Database.create!(@opts) }.should_not raise_error
    end
  
    it 'create should raise an error if an HTTP error occurs' do
      CouchDB.should_receive(:put).and_raise( CouchDB::RequestFailed )
      lambda{ Database.create!(@opts) }.should raise_error
    end      
  end
  
  describe '#exist?' do 
    it '#exists? should be false if the database doesn\'t yet exist in CouchDB land' do
      db = Database.new(@opts)
      db.should_not be_exist
    end
  
    it '#exists? should be true if the database does exist in CouchDB land' do
      db = Database.create(@opts)
      db.should be_exist
    end 
  end  
  
  describe '#info' do
    it '#info raise an error if the database doesn\'t exist' do 
      db = Database.new(@opts)
      lambda{ db.info }.should raise_error( CouchDB::ResourceNotFound )
    end

    it '#info should provide a hash of detail if it exists' do
      db = Database.create(@opts)
      lambda{ db.info }.should_not raise_error
    end 
  end            
   
  describe '#delete' do    
    it 'should delete itself' do 
      db = Database.create(@opts)
      db.should be_exists
      db.delete 
      db.should_not be_exist
    end
  
    it 'should return false if it doesn\'t exist' do 
      db = Database.new(@opts)
      db.should_not be_exists
      lambda{ db.delete }.should_not raise_error
      db.delete.should == false 
    end
  end
  
  describe '#delete!' do   
    it 'should delete itself' do 
      db = Database.create(@opts)
      db.should be_exists
      db.delete! 
      db.should_not be_exist
    end
  
    it 'should raise an error if the database doesn\'t exist' do 
      db = Database.new(@opts)
      db.should_not be_exists
      lambda{ db.delete! }.should raise_error
    end
  end      
  
  describe 'compaction' do  
    it 'should compact a database' do
      CouchDB.should_receive(:post).with( "#{@db.uri}/_compact" )
      @db.compact
    end  
  end 
  
  describe 'replication' do
    it 'should replicate on the same server when provided a database name' do
      data = {
        'source' => "#{@db.uri}",
        'target' => "#{@db.server.uri}/my_target"
      }
      CouchDB.should_receive(:post).with("#{@db.server.uri}/_replicate/", data)
      @db.save!
      @db.replicate(:my_target)
    end 
    
    it 'should create the target if it doesn\'t exist' do 
      @db.save!
      @db.replicate(:my_target)
      my_target = Database.new(:server => @db.server, :name => :my_target)
      my_target.should be_exist
      
      # cleanup
      my_target.delete
    end    
    
    it 'should replicate to another server' do 
      remote_db = Database.new(
        :name => :remote_database,
        :server => Server.new(:domain => 'myremoteserver.com')
      )
      data = {
        'source' => "#{@db.uri}",
        'target' => "#{remote_db.uri}"
      }
      remote_db.should_receive(:save).and_return( self )
      CouchDB.should_receive(:post).with("#{@db.server.uri}/_replicate/", data)
      @db.save!
      @db.replicate(remote_db) 
    end
    
    it 'should do it continuously, when asked nicely' do
      data = {
        'source' => "#{@db.uri}",
        'target' => "#{@db.server.uri}/my_target",
        'continuous' => true
      }
      CouchDB.should_receive(:post).with("#{@db.server.uri}/_replicate/", data)
      @db.save!
      @db.replicate(:my_target, true) 
    end    
  end         
    
  describe 'document managment' do 
    it 'should return all documents'
    describe 'bulk operations' do 
      it 'should bulk save'
      it 'should bulk delete'
      it 'should bulk update ??'
    end 
  end 
  
  describe 'slow view' do 
    it 'should receive a map reduce and produce a slow view'
  end
  
  describe 'design documents' do 
    it 'should return a list of design documents'
  end        
end  