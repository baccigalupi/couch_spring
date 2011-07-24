require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

# Conveniences for typing with tests ... 
Database =  CouchSpring::Database unless defined?( Database )
Server =    CouchSpring::Server unless defined?( Server )
Design =    CouchSpring::DesignDocument unless defined?( Design )
Document =  CouchSpring::Document unless defined?( Document )
ResultSet = CouchSpring::ResultSet unless defined?( ResultSet )

describe CouchSpring::DesignDocument do 
  before do
    @server = Server.new
    @server.clear!
    
    @db = Database.new(:user)
    
    @name = 'User'
    @design = Design.new(:name => @name, :database => @db) 
    
    class User < Document
    end
    User.database = @db
    User.database.name.should == 'user'   
  end 
  
  describe 'initialization' do
    it 'requires a name' do
      lambda{ Design.new(:database => @db) }.should raise_error(ArgumentError)
    end
    
    it 'requires a database' do
      lambda{ Design.new(:name => @name) }.should raise_error(ArgumentError)
    end
    
    it 'will set both the name and a database' do
      @design.database.should == @db
      @design.name.should == @name
    end
  end 
    
  describe 'crud operations' do
    it 'should build the correct uri' do
      @design.uri.should == 'http://127.0.0.1:5984/user/_design/User'
    end
      
    it 'should save' do 
      lambda{ @design.save! }.should_not raise_error
      lambda{ CouchSpring.get( @design.uri ) }.should_not raise_error
    end
    
    it 'get! should require a database' do
      @design.save!
      lambda{ Design.get!(:name => @design.name) }.should raise_error( ArgumentError )
      Design.get!(:name => @design.name, :database => @db).should == @design.reload
    end
    
    it 'get should require a database' do
      @design.save!
      lambda{ Design.get!(:name => @design.name) }.should raise_error( ArgumentError )
      Design.get(:name => @design.name, :database => @db).should == @design.reload
    end
    
    it 'delete! requires a database' do
      @design.save!
      @design.should_not be_new
      lambda{ Design.delete!(:name => @design.name) }.should raise_error( ArgumentError )
      lambda{ Design.delete!(:name => @design.name, :database => @db) }.should_not raise_error
    end
    
    it 'delete! requires a database' do
      @design.save!
      @design.should_not be_new
      lambda{ Design.delete!(:name => @design.name) }.should raise_error( ArgumentError )
      Design.delete!(:name => @design.name, :database => @db).should_not == false
    end
  end
  
  describe 'database' do
    it 'can set the database on the instance level' do
      @design.database.should == @db
      @design.database = Database.new(:new_foo)
      @design.database.name.should == 'new_foo'
      @design.database.new?.should == false
    end
  end
  
  describe 'views' do
    before(:each) do
      ResultSet.document_class = Document
    end
      
    it 'should be a Hash-like object' do 
      @design.views.should == Gnash.new
    end
    
    describe '<<, add, add!' do
      describe 'string as argument' do
        it 'should add a view with the right name' do
          @design << 'my_attribute'
          @design.views.keys.should == ['my_attribute']
        end
      
        it 'should autogenerate a generic map' do
          @design << 'my_attribute'
          @design.views[:my_attribute][:map].should match(/function\(doc\)/)
          @design.views[:my_attribute][:map].should match(/emit/)
        end
      
        it 'should not autogenerate a reduce function' do
          @design << 'my_attribute'
          @design.views[:my_attribute][:reduce].should be_nil
        end 
      end
      
      describe 'hash options as argument' do 
        it 'should add a view named with the options name key' do 
          @design << {:name => 'my_attribute'}
          @design.views.keys.should == ['my_attribute']
        end
        
        it 'should autogenerate a generic map' do
          @design << {:name => 'my_attribute'}
          @design.views[:my_attribute][:map].should match(/function\(doc\)/)
          @design.views[:my_attribute][:map].should match(/emit/)
        end
        
        it 'should autogenerate a generic map with class constraints' do
          @design << {:name => 'my_docs', :class_constraint => CouchSpring::Document }
          @design.views[:my_docs][:map].should match(/doc\['class_'\] == 'CouchSpring::Document'/)
        end
        
        it 'should autogenerate a generic map and insert preformed class constraints' do
          @design << {:name => 'user', :class_constraint => "doc['class'] == 'User'" }
          @design.views[:user][:map].should match(/doc\['class'\] == 'User'/)
        end  
        
        it 'should not autogenerate a reduce function' do
          @design << {:name => 'my_attribute'}
          @design.views[:my_attribute][:reduce].should be_nil
        end
        
        it 'should apply a custom map option when provided' do
          @design << {:name => 'my_attribute', :map => 'not the generic'}
          @design.views[:my_attribute][:map].should == 'not the generic'
        end
        
        it 'should apply a reduce option when provided' do
          @design << {:name => 'my_attribute', :reduce => 'I exist!'}
          @design.views[:my_attribute][:map].should match(/function\(doc\)/)
          @design.views[:my_attribute][:map].should match(/emit/) 
          @design.views[:my_attribute][:reduce].should == 'I exist!'
        end      
      end
      
      it 'add should act like <<' do
        @design.add :name => 'my_attribute', :map => 'not the generic'
        @design.views[:my_attribute][:map].should == 'not the generic'
      end
      
      it 'add! should save after adding the view' do
        @design.add! :name => 'my_attribute', :map => 'not the generic'
        @design.views.keys.should include( 'my_attribute' )
      end        
    end 
  
    describe 'default views' do
      it "should have an :all view with full documents from everything with the _class key"
    end
  end
  
  describe 'query' do
    before do
      (1..10).each do |num| 
        User.create!( :index => num )
      end 
      
      @design << :index
      @design.save!  
    end
       
    it 'should query by saved view' do
      lambda{ @design.query( :index ) }.should_not raise_error
    end 
    
    it 'should return a number of rows corresponding to all the documents in the query' do
      @docs = @design.query( :index )
      @docs.size.should == 10
    end
    
    it 'should return the documents themselves by default' do
      @docs = @design.query( :index )
      @docs.first.keys.should include( 'index' )
      @docs.first.class.should == User
    end
    
    it 'should throw an reasonable error if the class corresponding to the _class attribute is not found' do 
      @design.should_receive(:raw_query).and_return([{'class_' => 'NonExistent'}])
      lambda{ @design.query( :index ) }.should raise_error( Design::MissingClass, "NonExistent class not found. Maybe this class name has been changed. Or maybe you meant to use the design document's #raw_query method to return hashes instead of objects.")
    end
    
    it 'should limit query results' do
      @docs = @design.query( :index, :limit => 2 )
      @docs.size.should == 2
    end
    
    it 'should offset query results' do
      @docs = @design.query( :index, :limit => 2, :offset => 2)
      @docs.size.should == 2
      @docs.first[:index].should == 3
    end
    
    it 'should put in descending order' do
      @docs = @design.query( :index, :order => :desc )
      @docs.first[:index].should == 10
    end
    
    it 'should select a range' do
      @docs = @design.query( :index, :range => [2,4])
      @docs.size.should == 3
      @docs.first[:index].should == 2
    end
  end  

  describe 'calculations (reductions)' do
    it 'reduced_query! should automatically create the view if it does not exist'
    it 'should count'
    it 'should sum'
    it 'should average'
    it 'should min'
    it 'should max'
  end  
end  