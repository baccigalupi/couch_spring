require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe CouchSpring::Database do 
  before do
    @default_server = CouchSpring::Server.new
    @default_server.clear!
    
    @name = 'things'
    @db = CouchSpring::Database.new(@name)
  end
  
  after do
    CouchSpring.delete( @db.uri ) rescue nil
  end

  describe 'initialization' do
    describe 'name' do
      it 'should not require name for initialization' do
        lambda{ CouchSpring::Database.new }.should_not raise_error( ArgumentError )
      end

      it 'should have a default name of "ruby"' do
        database = CouchSpring::Database.new
        database.name.should == 'ruby'
      end

      it 'should escape the name, when one is provided' do
        db = CouchSpring::Database.new(:name => '&not::kosher*%')
        db.name.should == 'not__kosher'
      end

      it 'should accept Symbols as names' do
        db = CouchSpring::Database.new( :name => :my_name )
        db.name.should == 'my_name'
      end 
      
      it 'should accept the name as the first non hash argument' do
        db = CouchSpring::Database.new(:foo)
        db.name.should == 'foo'
      end   
    end
    
    describe 'validating the name' do
      it 'downcases name' do
        db = CouchSpring::Database.new('FOO')
        db.name.should == 'foo'
      end
      
      it 'strips illegal characters' do
        db = CouchSpring::Database.new('foo * bar')
        db.name.should == 'foobar'
      end
    end

    describe 'server' do
      it 'should have the default server if none is specified' do
        db = CouchSpring::Database.new
        db.server.should_not be_nil
        db.server.should == CouchSpring.server
      end

      it 'should accepts a symbol or string as the server parameter and maps it to a saved server' do
        user_server = CouchSpring::Server.new(:port => 8888)
        CouchSpring.server(:user, user_server)

        db = CouchSpring::Database.new(:server => :user)
        db.server.should == user_server

        db = CouchSpring::Database.new(:server => 'user')
        db.server.should == user_server
      end

      it 'accept a CouchSpring::Server object as the server parameter' do
        user_server = CouchSpring::Server.new(:port => 8888)
        db = CouchSpring::Database.new(:name => 'new_people', :server => user_server )
        db.server.should == user_server
      end
      
      it 'should have the right name when passed both sever options and server options' do
        user_server = CouchSpring::Server.new(:port => 8888)
        db = CouchSpring::Database.new('something_else', :server => user_server )
        db.server.should == user_server
        db.name.should == 'something_else'
      end
    end
    
    describe 'state' do
      it 'should be new?' do
        db = CouchSpring::Database.new('new_2_you')
        db.new?.should == true
      end
      
      it 'should not have to hit the database to know it is new' do
        db = CouchSpring::Database.new('new_4_you')
        CouchSpring.should_not_receive(:get)
        db.new?.should == true
      end
    end
  end
  
  describe 'comparison' do
    it 'should be == when the uris are the same' do
      @db.should == CouchSpring::Database.new(@name)
    end
  
    it 'should not be == to a non-database object' do
      thing = "not a database"
      thing.stub!(:uri).and_return(@db.uri)
      @db.should_not == thing
    end  
  end    

  describe 'uri' do
    it 'should use the default server and default database name' do
      db = CouchSpring::Database.new
      db.name.should == 'ruby'
      db.uri.should == "http://127.0.0.1:5984/ruby"
    end

    it 'should use the name when provided' do
      db = CouchSpring::Database.new( @name )
      db.name.should == 'things'
      db.uri.should == 'http://127.0.0.1:5984/things'
    end

    it 'should use the server when provided' do
      server = CouchSpring::Server.new(:port => 8888)
      db = CouchSpring::Database.new(:name => 'things', :server => server )
      db.uri.should == 'http://127.0.0.1:8888/things'
    end
  end

  describe 'crud operations' do
    describe 'save' do
      describe 'non ! method' do
        it 'should assure that a database instance has a database on the server' do
          lambda{ CouchSpring.get( @db.uri ) }.should raise_error
          @db.save.should_not == false
          lambda{ CouchSpring.get( @db.uri ) }.should_not raise_error
        end

        it 'should return false when the request fails' do
          CouchSpring.should_receive(:put).and_raise( CouchSpring::RequestFailed )
          @db.save.should == false
        end
      end

      describe '! method' do
        it 'should throw an exception when the ! form is used' do
          CouchSpring.should_receive(:put).and_raise( CouchSpring::RequestFailed )
          lambda{ @db.save!}.should raise_error
        end
      
        it 'should not raise an error if the database already exists' do
          @db.save.should_not == false
          db = CouchSpring::Database.new(@db.name)
          lambda { db.save! }.should_not raise_error
        end
      end
    
      describe 'state of newness' do
        it 'is not new on success' do
          @db.new?.should == true
          @db.save!
          @db.new?.should == false
        end
    
        it 'is still new on failure' do
          CouchSpring.should_receive(:put).and_raise( CouchSpring::RequestFailed )
          @db.save.should == false
          @db.new?.should == true
        end
    
        it 'is not new if the save fails because it already exists' do
          @db.save.should_not == false
          db = CouchSpring::Database.new(@db.name)
          db.save!
          db.new?.should == false
        end
      end
    end

    describe '#create' do
      it 'should generate a couchdb database for this instance if it doesn\'t yet exist' do 
        db = CouchSpring::Database.create(@name)
        lambda{ CouchSpring.get db.uri }.should_not raise_error
      end

      it 'should return an existing database if there is one' do
        @db.save
        @db.exist?.should == true
      
        db = CouchSpring::Database.create!(@name)
        db.should_not == false
        db.class.should == CouchSpring::Database
      end

      it 'should return false if an HTTP error occurs' do
        CouchSpring.should_receive(:put).and_raise( CouchSpring::RequestFailed )
        db = CouchSpring::Database.create( @name )
        db.should == false
      end
    end

    describe '#create!' do
      it 'should create and return a couchdb database if it doesn\'t yet exist' do
        @db.exist?.should == false
        db = CouchSpring::Database.create!(@name)
        @db.should == db
        db.exist?.should == true
      end
  
      it 'create! should not raise an error if the database already exists' do 
        @db.save 
        lambda{ CouchSpring::Database.create!(@name) }.should_not raise_error
      end

      it 'create should raise an error if an HTTP error occurs' do
        CouchSpring.should_receive(:put).and_raise( CouchSpring::RequestFailed )
        lambda{ CouchSpring::Database.create!(@name) }.should raise_error
      end
    end

    describe '#delete' do
      it 'should delete itself' do 
        @db.save!
        @db.delete 
        @db.exist?.should == false
      end
  
      it 'should return false if it doesn\'t exist' do 
        db = CouchSpring::Database.new(@name)
        db.exist?.should == false
      end
    end
  
    describe '#delete!' do
      it 'should delete itself' do 
        db = CouchSpring::Database.create(@name)
        db.exist?.should == true
        db.delete! 
        db.exist?.should == false
      end
  
      it 'should raise an error if the database doesn\'t exist' do 
        db = CouchSpring::Database.new(@name)
        db.exist?.should == false
        lambda{ db.delete! }.should raise_error
      end
    end      
  end
  
  describe 'general management' do
    describe 'class level #default' do
      it 'news a default database' do
        CouchSpring::Database.default.should == CouchSpring::Database.new
      end
      
      it '! will create the default database if it does not exist' do
        db = CouchSpring::Database.default!
        db.should == CouchSpring::Database.new
        db.new?.should == false
      end
    end
    
    describe '#exist?' do
      it '#exists? should be false if the database doesn\'t yet exist in CouchSpring land' do
        db = CouchSpring::Database.new(@name)
        db.should_not be_exist
      end

      it '#exists? should be true if the database does exist in CouchSpring land' do
        db = CouchSpring::Database.create(@name)
        db.should be_exist
      end
    end

    describe '#info' do
      it 'should return nil if the database does not exist' do
        lambda{ @db.info }.should_not raise_error
        @db.info.should == nil
      end

      it 'should raise an error if the database doesn\'t exist, and the ! method is used' do
        lambda{ @db.info! }.should raise_error( CouchSpring::ResourceNotFound )
      end

      it '#info should provide a hash of detail if it exists' do
        @db.save
        info = @db.info
        info.is_a?(Hash).should == true
        info['db_name'].should == @name
      end 
    end            
    
    it 'should compact! a database' do
      CouchSpring.should_receive(:post).with( "#{@db.uri}/_compact" )
      @db.compact!
    end

    describe 'changes' do
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
        target = CouchSpring::Database.new(:my_target)
        target.delete
      end

      describe 'integration' do
        it 'should work without error' do
          @db.save!
          db = CouchSpring::Database.create!(:my_target)
          lambda { @db.replicate(:my_target) }.should_not raise_error
        end

        it 'should create the target if it does not exist' do
          @db.save!
          lambda { @db.replicate(:new_target, :create => true) }.should_not raise_error
        end
      end

      describe 'mocked unit' do
        it 'should replicate on the same server when provided a database name' do
          data = {
            'source' => "#{@db.name}",
            'target' => "#{@db.server.uri}/my_target"
          }
          CouchSpring.should_receive(:post).with("#{@db.server.uri}/_replicate/", data)
          @db.save!
          @db.replicate(:my_target)
        end 

        it 'should replicate to another server' do
          remote_db = CouchSpring::Database.new(
            :name => :remote_database,
            :server => CouchSpring::Server.new(:domain => 'myremoteserver.com')
          )
          data = {
            'source' => "#{@db.name}",
            'target' => "#{remote_db.uri}"
          }
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
          @db.replicate(:my_target, {:filter => "my_filter_name", :params => ['foo', 'bar', 'etc']})
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
    end

    # TODO: registry, to prevent hitting the couchdb server again and again
  end
    
  describe 'bulk operations' do 
    it 'should get all documents' do
      pending
    end  

    it 'should save many docs at once'
    it 'should update many docs at once'
    it 'should be smart enough to mix saves with updates without effort'
    it 'should bulk delete'
    it 'should bulk save, update and delete in a single request'
  end

  describe 'design documents' do
    it 'should return a list of design documents'
  end
end
