require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe CouchSpring::DocumentBase do 
  before do
    @server = CouchSpring::Server.new
    @server.clear!
    CouchSpring::DocumentBase.database(:clear)
    
    @db = CouchSpring::Database.new # default
    
    @params = {
      :id => 'my_slug/thaz-right',
      :rev => "shouldn't change yo!",
      :more => "my big stuff"
    }
    
    @doc = CouchSpring::DocumentBase.new( @params ) 
  end  
  
  describe 'initialization' do
    it 'should initialize with a hash of values accessible by symbol or string' do 
      @doc[:more].should == 'my big stuff'
      @doc['more'].should == 'my big stuff'
    end
    
    it 'should set the id with the initialization hash' do 
      @doc.id.should == 'my_slug/thaz-right' 
    end
    
    it 'should escape the id' do  
      @doc[:_id].should == 'my_slug%2Fthaz-right'
    end
    
    it 'should not set the rev and it should discard those keys' do
      @doc.rev.should == nil # same as @doc[:_rev]
      @doc[:rev].should == nil
    end 
    
    it 'should set the rev when _rev param is passed in' do
      doc = CouchSpring::DocumentBase.new( @params.merge(:_rev => 'my_rev') )
      doc.rev.should_not be_nil
      doc.rev.should == 'my_rev'
    end  
  end
  
  describe 'database' do
    class SubDoc < CouchSpring::DocumentBase; end
     
    before do
      @things_db = CouchSpring::Database.new(:name => 'things')
    end
    
    describe 'class level' do 
      describe 'reading' do
        it 'should have a default database' do
          CouchSpring::DocumentBase.database.should == @db
        end
      
        it 'the default database should exist' do
          CouchSpring::DocumentBase.database.exist?.should be_true
        end
      end
       
      describe 'setting' do
        it 'should use and save a custom database' do
          CouchSpring::DocumentBase.database = @things_db
          CouchSpring::DocumentBase.database.should == @things_db
          CouchSpring::DocumentBase.database.exist?.should be_true
        end 
      
        it 'should have a custom database when passed a symbol' do
          CouchSpring::DocumentBase.database = @db
          CouchSpring::DocumentBase.database.should_not == @things_db
          CouchSpring::DocumentBase.database = :things 
          CouchSpring::DocumentBase.database.should == @things_db
        end
        
        it 'should have a custom database when passed a string' do
          CouchSpring::DocumentBase.database = @db
          CouchSpring::DocumentBase.database.should_not == @things_db
          CouchSpring::DocumentBase.database = 'things' 
          CouchSpring::DocumentBase.database.should == @things_db
        end
      end
      
      describe 'clearing' do
        it 'should work when "getter" method recieves the :clear symbol' do
          CouchSpring::DocumentBase.database.should == @db
          CouchSpring::DocumentBase.database.exist?.should == true
          CouchSpring::DocumentBase.database(:clear)
          CouchSpring::DocumentBase.instance_variable_get('@db').should == nil
        end
      end
      
      describe 'inheritance' do
        it 'should inheirit its default database from the superclass' do
          CouchSpring::DocumentBase.database = @things_db 
          SubDoc.database(:clear)
          CouchSpring::DocumentBase.database = @things_db
          SubDoc.database.should == @things_db
        end
      
        it 'should have different database from the subclass on customization' do
          CouchSpring::DocumentBase.database.should == @db
          SubDoc.database = @things_db 
          SubDoc.database.should_not == @db
          SubDoc.database.should == @things_db  
        end  
      end    
    end 
  
    describe 'instance level' do
      it 'is whatever the class level is' do
        SubDoc.database = @things_db
        SubDoc.new.database.should == @things_db
      end
    end
  end
  
  describe 'uri' do 
    it 'should have use the default database uri by default with the document id'  do 
      @doc.database.should == @db # just making sure
      @doc.uri.should == "#{@db.uri}/my_slug%2Fthaz-right"
    end
    
    it 'should reflect the non-default database name' do
      db = CouchSpring::Database.create('my_class') 
      CouchSpring::DocumentBase.database = db
      @doc.uri.should == "#{db.uri}/my_slug%2Fthaz-right"
    end
    
    it 'should use a server generated uuid for the id if an id is not provided' do
      params = @params.dup
      params.delete(:id)
      doc = CouchSpring::DocumentBase.new( params )
      doc.uri.should match(/\A#{doc.database.uri}\/[a-f0-9]*\z/)
    end  
  end 
  
  describe 'saving' do
    before(:each) do
      CouchSpring::DocumentBase.database = @db 
    end  
    
    describe "#save" do
      it 'saving should create a document in the database' do 
        @doc.save
        lambda{ CouchSpring.get( @doc.uri ) }.should_not raise_error
      end
    
      it 'return itself if it worked' do
        return_value = @doc.save
        return_value.class.should == CouchSpring::DocumentBase 
        return_value.id.should == @doc.id
      end
    
      it 'should return false if it did not work' do
        @doc.save!
        @doc[:_rev] = 'not a rev' # should raise Conflict
        @doc.save.should == false
      end
    
      it 'saving should update the "id" and "rev"' do
        doc_id = @doc.id
        doc_rev = @doc.rev
        @doc.save!
        @doc[:_id].should_not == doc_id
        @doc.rev.should_not == doc_rev
      end
    end
    
    it '#save! should raise an error on failure when creating' do
      @doc.save!
      @doc.delete(:_rev) # should create a conflict
      lambda{ @doc.save! }.should raise_error( CouchSpring::Conflict )
    end
    
    describe '#create' do 
      it 'should return itself when successful' do
        doc = CouchSpring::DocumentBase.create(@params)
        doc.class.should == CouchSpring::DocumentBase
        doc.rev.should_not be_nil
      end
    
      it 'should return false when not successful' do 
        @doc.save! # database should already have a document with this id and a non-nil rev
        doc = CouchSpring::DocumentBase.create( @params )
        doc.should == false
      end
        
      it 'the ! form should raise an error when not successful' do
        @doc.save!
        lambda{ CouchSpring::DocumentBase.create!( @params ) }.should raise_error( CouchSpring::Conflict )
      end  
    end
    
    it 'should #reload' do
      @doc.save!
      @doc[:noodle] = 'spaghetti'
      reloaded = @doc.reload 
      reloaded.class.should == CouchSpring::DocumentBase
      @doc[:noodle].should be_nil
    end
    
    describe 'updating intrinsic values' do
      # this might have been covered in other save tests, 
      # TODO: check it out, refactor, etc.
      it 'saving after a change should change the revision number' do 
        @doc.save! 
        rev = @doc.rev
        _id = @doc[:_id]
        id = @doc[:id] 
        @doc['more'] = 'less ... really'
        @doc['newness'] = 'overrated'
        @doc.save!
        @doc.id.should == id
        @doc[:_id].should == _id
        @doc.rev.should_not == rev
      end
      
      it 'saving after a change should retain changed data' do
        @doc.save! 
        @doc['more'] = 'less ... really'
        @doc['newness'] = 'overrated'
        @doc.save!
        
        @doc.reload
        @doc['more'].should == 'less ... really'
        @doc['newness'].should == 'overrated'
      end  
    end    
  end
  
  describe 'getting' do
    it 'should get a document from its id' do 
      @doc.save!
      CouchSpring::DocumentBase.get( @doc.id ).should_not == false
    end 
    
    it 'should return false if the document is not found' do  
      CouchSpring::DocumentBase.get( 'not_an_id' ).should be_false
    end 
    
    it '#get! should raise an error when not found' do
      lambda{ CouchSpring::DocumentBase.get!( 'yup_not_here' ) }.should raise_error
    end   
    
    it 'returned document should have an id' do
      @doc.save!
      document = CouchSpring::DocumentBase.get!( @doc.id )
      document.id.should == @doc.id
    end
    
    it 'returned document should have an id even if not explicitly set' do
      doc = CouchSpring::DocumentBase.new(:this => 'that')
      doc.save!
      retrieved = CouchSpring::DocumentBase.get!( doc.id )
      retrieved.id.should_not be_nil
      retrieved.id.should_not be_empty
    end 
    
    it 'returned document should have a rev' do
      @doc.save!
      document = CouchSpring::DocumentBase.get!( @doc.id )
      document.rev.should_not be_nil
    end     
  end  
  
  describe 'deleting' do
    it 'should #delete a record' do
      @doc.save!
      @doc.should be_exists
      @doc.delete
      @doc.should_not be_exists
    end
    
    it 'should return true on successful #delete' do
      @doc.save!
      @doc.delete.should == true
    end  
      
    it 'should return false when it fails' do 
      @doc.save!
      CouchSpring.should_receive(:delete).and_raise( CouchSpring::Conflict )
      @doc.delete.should == false
    end
      
    it 'should remove all versions of the document when ! method is used' do 
      @doc.save!
      @doc[:one] = 1
      @doc.save!
      @doc[:two] = 2
      @doc.save!  
      CouchSpring.should_receive(:delete).exactly(3).times
      @doc.delete!
    end
    
    it 'should have a class method #delete that takes an id and deletes the related document' do
      @doc.save!
      lambda{ CouchSpring.get( CouchSpring::Document.uri_for(@doc.id) ) }.should_not raise_error
      CouchSpring::DocumentBase.delete( @doc.id ) 
      lambda{ CouchSpring.get( CouchSpring::Document.uri_for(@doc.id) ) }.should raise_error
    end 
    
    it 'class method should return false on failure' do
      CouchSpring::DocumentBase.delete('not_there').should == false
    end  
    
    it 'should have a #delete! method that raises an error on failure' do
      lambda{ CouchSpring::DocumentBase.delete!('not_there') }.should raise_error
    end     
  end  
  
  describe 'core attributes' do
    it 'should be new before it exists in the database' do
      @doc.should be_new
    end 
    
    it 'should #exist? if it has been saved to CouchSpring' do 
      @doc.save!
      @doc.should be_exists
    end
    
    it 'should not #exist? if the document is new' do
      @doc.should_not be_exists
    end
     
    
    it 'rev should not be publicly settable' do 
      lambda{ @doc.rev = 'my_rev' }.should raise_error
    end 
    
    describe 'updating the id, post save' do
      before(:each) do
        @doc.save!
        @doc.id = 'something/new_and_fresh'
      end  
      
      it 'should change the id' do 
        @doc.id.should == 'something/new_and_fresh'
      end
        
      it 'should change the _id' do
        @doc[:_id].should == 'something%2Fnew_and_fresh'
      end
        
      it 'should successfully save' do
        lambda{ @doc.save! }.should_not raise_error
        @doc.reload[:id].should == 'something/new_and_fresh'
      end
        
      it 'should delete earlier versions on save' do 
        @doc.save!
        lambda{ CouchSpring.get!( "#{@doc.database.uri}/aqua/my_slug%2Fthaz-right") }.should raise_error
      end  
    end    
  
    describe 'revisions' do
      it 'should be an empty array for a new record' do
        @doc.should be_new # just to check 
        @doc.revisions.should == []
      end 
    
      it 'should have one value after the document is saved' do 
        @doc.save!
        @doc.revisions.size.should == 1
        @doc.revisions.first.should == @doc[:_rev]
      end
    
      it 'should continue adding revisions with each save' do 
        @doc.save!
        @doc['new_attr'] = 'my new attribute, yup!'
        @doc.save!
        @doc.revisions.size.should == 2
      end     
    end    
  end   
  
  describe 'copying' do
    it 'should copy a doc to a new id/location' do
      pending( 'waiting for someone to need this. Lots of work, no benefit right now.') 
      @doc.save!
      copy = @doc.copy('new_id')
      lambda{ CouchSpring.get!( "#{copy.uri}" ) }.should_not raise_error
    end
    
    it 'should escape the new document id'
    it 'should return true on success'
    it 'should return false on failure'
    it 'should raise an error on failure when the ! form is used'
  end
  
  describe 'attachments' do
    before(:each) do
      @doc.delete! if @doc.exists?
      @file = File.new( File.dirname( __FILE__ ) + '/attachments/image_attach.png' )
    end
       
    it 'should have an accessor for storing attachments' do 
      @doc.attachments.should == CouchSpring::Attachments.new( @doc )
    end
    
    it 'should add attachments' do 
      @doc.attachments.add(:my_file, @file)
      @doc.attachments[:my_file].should == @file
    end
    
    it 'should pack attachments' do
      @doc.attachments.add(:my_file, @file)
      @doc.attachments.add("dup.png", @file)
      pack = @doc.attachments.pack
      pack.keys.should include('my_file', 'dup.png')
    end
    
    it 'should pack attachments to key _attachments on save' do 
      @doc.attachments.add(:my_file, @file)
      @doc.attachments.add("dup.png", @file)
      pack = @doc.attachments.pack
      @doc.save!
      @doc[:_attachments].should == pack
    end   
    
    it 'should pack attachments before save' do 
      @doc.attachments.add(:my_file, @file)
      @doc.attachments.add("dup.png", @file)
      pack = @doc.attachments.pack
       
      @doc.attachments.should_receive( :pack ).and_return( pack )
      @doc.save!
    end 
    
    it 'should pack attachments before save' do 
      @doc.attachments.add(:my_file, @file)
      @doc.attachments.add("dup.png", @file)
      pack = @doc.attachments.pack
       
      @doc.attachments.should_receive( :pack ).and_return( pack )
      @doc.save!
    end 
    
    it 'should be correctly formed in database' do
      @doc.attachments.add(:my_file, @file)
      @doc.attachments.add("dup.png", @file)
      @doc.save!
      @doc.reload
      
      @doc[:_attachments]['dup.png']['content_type'].should == 'image/png'
      @doc[:_attachments]['dup.png']['stub'].should == true
      (@doc[:_attachments]['my_file']['length'] > 0).should == true
      @doc[:_attachments]['my_file']['content_type'].should == 'image/png'
      @doc[:_attachments]['my_file']['stub'].should == true
      (@doc[:_attachments]['my_file']['length'] > 0).should == true
    end 
    
    it 'should be retrievable by a url' do
      @doc.attachments.add(:my_file, @file)
      @doc.attachments.add("dup.png", @file)
      @doc.save!
      
      url = @doc.attachments.uri_for('dup.png')  
      lambda{ CouchSpring.get( url, :streamable => true ) }.should_not raise_error
    end  
    
    it 'should save and retrieve the data correctly' do 
      @doc.attachments.add(:my_file, @file)
      @doc.attachments.add("dup.png", @file)
      @doc.save!
      
      file = @doc.attachments.get!( :my_file )
      file.read.should == @file.read
    end
  end  
           
end  