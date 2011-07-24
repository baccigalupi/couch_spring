require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

Document = CouchSpring::Document unless defined?( Document )

describe Document  do 
  describe 'class level bulk operations' do
    class Thing < Document; end 

    before do
      Thing.database.delete_all
    end
    
    it 'should save the document class to a hidden field' do
      thing = Thing.create!(:amagig => true)  
      thing[:class_].should == 'Thing'
    end
    
    it 'should return a count of all records' do
      old_count = Thing.count
      things = [
        Thing.create!( :foo => 'bar' ),
        Thing.create!( :bar => 'zar' )
      ]
      Thing.count.should == old_count + 2
    end 
      
    it 'should delete all' do
      pending
      Thing.count.should == 0
      things = [
        Thing.create!( :foo => 'bar' ),
        Thing.create!( :bar => 'zar' )
      ]
      
      Thing.count.should == 2
      Thing.delete_all
      Thing.count.should == 0
    end
  end  
  
  describe 'design document' do
    it 'design_name should default to name of document class' do
      Document.design_name.should == 'CouchSpring::Document'
      class Rat < Document; end
      Rat.design_name.should == 'Rat'  
    end  
    
    it 'the design name can be set' do 
      Document.design_name = 'my_app'
      Document.design_name.should == 'my_app'
    end  
    
    it 'should create a design document if there is a design_name but the design document exists' do
      CouchSpring::DesignDocument.delete!( :name => 'User', :database => Thing.database )
      
      Document.design_name = 'User'
      lambda{ CouchSpring::DesignDocument.get!( :name => 'User', :database => Thing.database ) }.should raise_error
      Document.design_document.should_not == false
      lambda{ CouchSpring::DesignDocument.get!( :name => 'User', :database => Thing.database ) }.should_not raise_error 
    end
    
    it 'should retrieve a design document if there is a design_name and the design document exists' do
      CouchSpring::DesignDocument.delete!( :name => 'User', :database => Thing.database )
      CouchSpring::DesignDocument.create!( :name => 'User', :database => Thing.database )
      # ensures that the record exists, before the real test
      lambda{ CouchSpring::DesignDocument.get( :name => 'User', :database => Thing.database) }.should_not raise_error 
      Document.design_document.should_not be_nil 
      Document.design_document.database.should == Document.database
    end  
  end  
  
  describe 'queries' do 
    before(:each) do
      pending 'make query creation delegators'
      (1..10).each do |num| 
        Document.create!( :index => num )
      end
      @design << :index
      @design.save!    
    end
    
    describe 'saving queries' do
      it '#build_query should delegate to the design document\'s #<< method'
    end
    
    describe '#query' do
      it 'should perform a saved query, if the query index is given'
      it 'should perform a dynamic query if index not given'
    end  
    
    describe 'dynamic queries (slow)' do
    end
    
    describe 'saved queries (delegation to the design doc)' do  
      describe 'all' do
        it 'should have that query' do 
          design = Thing.design_document 
          design.views.keys.should include 'all'
        end 
        
        it 'should find all the documents of that type'
        
      end
    end
  end  
end  