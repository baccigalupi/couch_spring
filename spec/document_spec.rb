require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

Document = CouchSpring::Document unless defined?( Document )

describe Document  do 
  describe 'class level bulk operations' do
    # These operations will delegate to the classes Database
    # but will be really convenient on the document class
  end  
  
  describe 'design document' do
    it 'design_name should default to name of document class' do
      Document.design_name.should == 'CouchSpring::Document'
      class Rat < Document
      end
      Rat.design_name.should == 'Rat'  
    end  
    
    it 'the design name can be set' do 
      Document.design_name = 'my_app'
      Document.design_name.should == 'my_app'
    end  
    
    it 'should create a design document if there is a design_name but the design document exists' do 
      CouchSpring::DesignDocument.delete( 'User' ) # in case it exists
      
      Document.design_name = 'User'
      lambda{ CouchSpring::DesignDocument.get!( 'User' ) }.should raise_error
      Document.design_document.should_not == false
      lambda{ CouchSpring::DesignDocument.get!( 'User') }.should_not raise_error 
    end
      
    
    it 'should have the same database as the document class' do
      database = CouchSpring::Database.new(:name => 'things')  
      Document.database = database
      Document.design_document.database.should == database
    end  
    
    it 'should retrieve a design document if there is a design_name and the design document exists' do
      CouchSpring::DesignDocument.delete( 'User' )
      CouchSpring::DesignDocument.create!( :name => 'User' )
      # ensures that the record exists, before the real test
      lambda{ CouchSpring::DesignDocument.get( 'User') }.should_not raise_error 
      Document.design_document.should_not be_nil 
      Document.design_document.database.should == Document.database
    end  
  end  
  

end  