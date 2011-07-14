require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

Server = CouchSpring::Server unless defined?( Server )
Database = CouchSpring::Database unless defined?( Database )

describe Database do 
  before(:each) do
    @default_server = Server.new
    @default_server.clear!
    
    CouchSpring.delete( @db.uri ) rescue nil
  end

  describe 'equality' do
    it 'should be == when the uris are the same' do 
      @db.should == Database.new(@name)
    end
  
    it 'should not be == to a non-database object' do 
      thing = "not a database"
      thing.stub!(:uri).and_return(@db.uri)
      @db.should_not == thing
    end  
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
        db = Database.new(:name => '&not::kosher*%')
        db.name.should == 'not__kosher'
      end

      it 'should accept Symbols as names' do
        db = Database.new( :name => :my_name )
        db.name.should == 'my_name'
      end 
      
      it 'should accept the name as the first non hash argument' do
        db = Database.new(:foo)
        db.name.should == 'foo'
      end   
    end
    
    describe 'validating the name' do
      it 'downcases name' do
        db = Database.new('FOO')
        db.name.should == 'foo'
      end
      
      it 'strips illegal characters' do
        db = Database.new('foo * bar')
        db.name.should == 'foobar'
      end
    end

    describe 'server' do
      it 'should have the default server if none is specified' do
        db = Database.new
        db.server.should_not be_nil
        db.server.should == CouchSpring.server
      end

      it 'should accepts a symbol or string as the server parameter and maps it to a saved server' do
        user_server = Server.new(:port => 8888)
        CouchSpring.server(:user, user_server)

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
      
      it 'should have the right name when passed both sever options and server options' do
        user_server = Server.new(:port => 8888)
        db = Database.new('something_else', :server => user_server )
        db.server.should == user_server
        db.name.should == 'something_else'
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
      db = Database.new( @name )
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
      lambda{ CouchSpring.get( @db.uri ) }.should raise_error
      @db.save.should_not == false
      lambda{ CouchSpring.get( @db.uri ) }.should_not raise_error
    end

    it 'should return false when the request fails' do
      CouchSpring.should_receive(:put).and_raise( CouchSpring::RequestFailed )
      @db.save.should == false
    end

    it 'should throw an exception when the ! form is used' do
      CouchSpring.should_receive(:put).and_raise( CouchSpring::RequestFailed )
      lambda{ @db.save!}.should raise_error
    end
  end

  describe '#create' do
    before(:each) do
      CouchSpring.delete( @db.uri ) rescue nil
    end  
  
    it 'should generate a couchdb database for this instance if it doesn\'t yet exist' do 
      db = Database.create(@name)
      lambda{ CouchSpring.get db.uri }.should_not raise_error
    end

    it 'should an existing database if there is one' do
      Database.create!(@name)
      db = Database.create!(@name)
      db.should_not == false
      db.class.should == Database
    end

    it 'should return false if an HTTP error occurs' do
      CouchSpring.should_receive(:put).and_raise( CouchSpring::RequestFailed )
      db = Database.create( @name )
      db.should == false
    end
  end

  describe '#create!' do
    it 'should create and return a couchdb database if it doesn\'t yet exist' do
      lambda{ CouchSpring.get db.uri }.should raise_error
      db = Database.create!(@name)
      lambda{ CouchSpring.get db.uri }.should_not raise_error
    end
  
    it 'create! should not raise an error if the database already exists' do 
      Database.create(@name) 
      lambda{ Database.create!(@name) }.should_not raise_error
    end

    it 'create should raise an error if an HTTP error occurs' do
      CouchSpring.should_receive(:put).and_raise( CouchSpring::RequestFailed )
      lambda{ Database.create!(@name) }.should raise_error
    end
  end

  describe '#exist?' do
    it '#exists? should be false if the database doesn\'t yet exist in CouchSpring land' do
      db = Database.new(@name)
      db.should_not be_exist
    end

    it '#exists? should be true if the database does exist in CouchSpring land' do
      db = Database.create(@name)
      db.should be_exist
    end
  end

  describe '#info' do
    it '#info raise an error if the database doesn\'t exist' do
      db = Database.new(@name)
      lambda{ db.info }.should raise_error( CouchSpring::ResourceNotFound )
    end

    it '#info should provide a hash of detail if it exists' do
      db = Database.create(@name)
      lambda{ db.info }.should_not raise_error
    end 
  end            
   
  describe '#delete' do
    it 'should delete itself' do 
      db = Database.create(@name)
      db.exist?.should == true
      db.delete 
      db.exist?.should == false
    end
  
    it 'should return false if it doesn\'t exist' do 
      db = Database.new(@name)
      db.exist?.should == false
    end
  end
  
  describe '#delete!' do   
    it 'should delete itself' do 
      db = Database.create(@name)
      db.exist?.should == true
      db.delete! 
      db.exist?.should == false
    end
  
    it 'should raise an error if the database doesn\'t exist' do 
      db = Database.new(@name)
      db.exist?.should == false
      lambda{ db.delete! }.should raise_error
    end
  end      
  
  describe 'general management' do
    it 'should compact! a database' do
      CouchSpring.should_receive(:post).with( "#{@db.uri}/_compact" )
      @db.compact!
    end

    it 'should report changes' do
      CouchSpring.should_receive(:get).with( "#{@db.uri}/_changes").and_return({})
      @db.changes
    end 

    it 'should report changes since a given sequence' do
      CouchSpring.should_receive(:get).with( "#{@db.uri}/_changes?since=14").and_return({})
      @db.changes(14)
    end
  end
  
  describe 'replication' do
    after do
      target = Database.new(:my_target)
      target.delete
    end
    
    it 'should replicate on the same server when provided a database name' do
      data = {
        'source' => "#{@db.name}",
        'target' => "#{@db.server.uri}/my_target"
      }
      CouchSpring.should_receive(:post).with("#{@db.server.uri}/_replicate/", data)
      @db.save!
      @db.replicate(:my_target)
    end 
    
    it 'should really work' do
      @db.save!
      @db.replicate(:my_target)
      my_target = Database.new(:server => @db.server, :name => :my_target)
      my_target.exist?.should == true
    end    

    it 'should replicate to another server' do
      remote_db = Database.new(
        :name => :remote_database,
        :server => Server.new(:domain => 'myremoteserver.com')
      )
      data = {
        'source' => "#{@db.name}",
        'target' => "#{remote_db.uri}"
      }
      remote_db.should_receive(:save).and_return( self )
      CouchSpring.should_receive(:post).with("#{@db.server.uri}/_replicate/", data)
      @db.save!
      @db.replicate(remote_db)
    end
    
    it 'should create the target database when that option is passed' do
      data = {
        'source' => @db.name,
        'target' => "#{@db.server.uri}/my_target",
        'create_target' => true
      }
      CouchSpring.should_receive(:post).with("#{@db.server.uri}/_replicate/", data)
      @db.save!
      @db.replicate(:my_target, {:create => true})
    end
    
    it 'should do it continuously, when asked nicely' do
      data = {
        'source' => "#{@db.name}",
        'target' => "#{@db.server.uri}/my_target",
        'continuous' => true
      }
      CouchSpring.should_receive(:post).with("#{@db.server.uri}/_replicate/", data)
      @db.save!
      @db.replicate(:my_target, {:continuous => true}) 
    end
    
    it 'should cancel replication when that option is passed in' do
      data = {
        'source' => "#{@db.name}",
        'target' => "#{@db.server.uri}/my_target",
        'cancel' => true
      }
      CouchSpring.should_receive(:post).with("#{@db.server.uri}/_replicate/", data)
      @db.save!
      @db.replicate(:my_target, {:cancel => true})
    end
    
    it 'should use the proxy option when requested' do
      data = {
        'source' => "#{@db.name}",
        'target' => "#{@db.server.uri}/my_target",
        'proxy' => 'http://proxier.org'
      }
      CouchSpring.should_receive(:post).with("#{@db.server.uri}/_replicate/", data)
      @db.save!
      @db.replicate(:my_target, {:proxy => "http://proxier.org"})
    end
    
    it 'should filter via the design document\'s filter' do
      data = {
        'source' => "#{@db.name}",
        'target' => "#{@db.server.uri}/my_target",
        'filter' => 'my_filter_name'
      }
      CouchSpring.should_receive(:post).with("#{@db.server.uri}/_replicate/", data)
      @db.save!
      @db.replicate(:my_target, {:filter => "my_filter_name"})
    end
    
    it 'should use the query params when provided' do
      data = {
        'source' => "#{@db.name}",
        'target' => "#{@db.server.uri}/my_target",
        'filter' => 'my_filter_name',
        'query_params' => ['foo', 'bar', 'etc']
      }
      CouchSpring.should_receive(:post).with("#{@db.server.uri}/_replicate/", data)
      @db.save!
      @db.replicate(:my_target, {:filter => "my_filter_name", :query_params => ['foo', 'bar', 'etc']})
    end
    
    it 'should filter on doc_ids when provided' do
      data = {
        'source' => "#{@db.name}",
        'target' => "#{@db.server.uri}/my_target",
        'doc_ids' => ['1', '2', '3']
      }
      CouchSpring.should_receive(:post).with("#{@db.server.uri}/_replicate/", data)
      @db.save!
      @db.replicate(:my_target, {:doc_ids => ['1','2','3']})
    end
  end         
    
  describe 'document managment' do 
    it 'should return all documents' do
      pending
    end  
    
    describe 'bulk operations' do 
      @db.replicate(:my_target, true)
    end
  end

  describe 'document managment' do
    it 'should return all documents' do
    end

    describe 'bulk operations' do
      it 'should save'
      it 'should update'
      it 'should be smart enough to mix saves with updates without effort'
      it 'should bulk delete'
      it 'should bulk save, update and delete in a single request'
    end
  end

  describe 'slow view' do
    it 'should receive a map reduce and produce a slow view'
  end

  describe 'design documents' do
    it 'should return a list of design documents'
  end
end
