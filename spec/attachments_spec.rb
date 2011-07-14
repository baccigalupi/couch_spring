require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

# Conveniences for typing with tests ... 
Attachments =   CouchSpring::Attachments unless defined?( Attachments )
Document =      CouchSpring::Document unless defined?( Document )

describe CouchSpring::Attachments do
  before(:each) do
    @doc = Document.new(:id => 'attachments_doc')
    @doc.delete!
    @attachments = Attachments.new( @doc )
    @file = File.new( File.dirname( __FILE__ ) + '/attachments/image_attach.png' )
  end
   
  describe 'initialization' do
    it 'should initialize with a document uri' do
      lambda{ Attachments.new }.should raise_error( ArgumentError )
      lambda{ Attachments.new( @doc )}.should_not raise_error( ArgumentError )
    end
  
    it 'should initialize with an optional hash' do
      lambda{ Attachments.new( @doc, {:my_file => @file})}.should_not raise_error( ArgumentError )
    end
    
    it 'when initializing with a hash, it should check that each key is a string and each value is a file' do
      lambda{ Attachments.new( @doc, { 1 => @file }) }.should raise_error( ArgumentError  )
      lambda{ Attachments.new( @doc, {:my_file => 1}) }.should raise_error( ArgumentError )
    end
    
    it 'document should be an object reference to the original document, not a dup' do 
      @attachments.document.should === @doc
    end       
  end     
  
  describe 'attachment_uri' do 
    it 'should raise an error if the document has no id' do
      attachments = Attachments.new( Document.new )
      attachments.add( :my_file, @file )
      lambda{ attachments.uri_for( :my_file ) }.should raise_error( ArgumentError )
    end 
    
    it 'should not include revision information if the document is new' do
      @attachments.add( :my_file, @file )
      @attachments.uri_for( :my_file ).should_not include( '?rev=')
    end
      
    it 'should include revision information if the document has been saved' do 
      @doc.save!
      @attachments.add( :my_file, @file )
      @attachments.uri_for( :my_file ).should include( '?rev=')
    end
    
    it 'should construct a valid attachment uri' do
      @attachments.add(:my_file, @file )
      @attachments.uri_for( :my_file ).should == "http://127.0.0.1:5984/ruby/attachments_doc/my_file"
    end
    
    it 'should construct a get attachment uri without the revision information' do 
      @doc.save!
      @attachments.add( :my_file, @file )
      @attachments.uri_for( :my_file, false ).should_not include( '?rev=')
    end      
  end   
  
  describe 'adding attachments' do 
    it 'should have a method #add that takes a name and a file' do 
      @attachments.should respond_to( :add )
      lambda{ @attachments.add }.should raise_error( ArgumentError )
      lambda{ @attachments.add( :my_file ) }.should raise_error( ArgumentError )
      lambda{ @attachments.add( :my_file, :not_a_file ) }.should raise_error( ArgumentError )
      lambda{ @attachments.add( [], @file ) }.should raise_error( ArgumentError )
      lambda{ @attachments.add( :my_file, @file ) }.should_not raise_error( ArgumentError )
    end 
  
    it 'should add a valid hash to the attachments container' do
      @attachments.add( :my_file, @file )
      @attachments[:my_file].should == @file
    end
    
    it 'should save the attachment to the database' do
      lambda{ @attachments.add!( :my_file, @file ) }.should_not raise_error
      lambda{ CouchSpring.get( @attachments.uri_for(:my_file) ) }.should_not raise_error 
    end
    
    it 'should have the right mime-type after addition to database' do 
      @attachments.add!( :my_file, @file )
      attach_hash = CouchSpring.get( @attachments.uri_for(:my_file) )
      attach_hash['content_type'].should == 'image/png'
    end    
  end
  
  describe 'removing attachments' do
    it '#delete should delete an attachment from the collection' do 
      @attachments.add( :my_file, @file )
      @attachments.delete( :my_file ).should == @file
      @attachments[:my_file].should be_nil
    end
    
    it '#delete! should remove an attachment from the collection and database' do 
      @attachments.add!( :my_file, @file )
      @attachments.delete!( :my_file )
      lambda{ CouchDB.get!( @attachments.uri_for(:my_file) ) }.should raise_error #( Aqua::ObjectNotFound )
    end   
  end
  
  describe 'retrieving attachments' do
    it 'should return a file if found locally' do
      @attachments.add!( :my_file, @file )
      @attachments.should_not_receive(:get!)
      @attachments.get(:my_file).should == @file
    end
    
    it 'should request a file from the database when not found locally' do 
      @attachments.add!( :my_file, @file )
      @attachments.delete( :my_file ) # just deletes the local reference
      @attachments.should_receive(:get!)
      @attachments.get(:my_file) 
    end 
    
    it 'should return a Tempfile from the database' do
      @attachments.add!( :my_file, @file )
      @attachments.delete( :my_file ) # just deletes the local reference
      @attachments.get(:my_file).class.should == Tempfile
    end
    
    it 'should have the same data as the original file' do 
      @attachments.add!( :my_file, @file )
      file = @attachments.get!(:my_file)
      read_binary(file).should == read_binary(@file)
      # file.read.should == @file.read
    end
    
    it 'should stream an attachment' do
      @attachments.add!( :my_file, @file )
      data = @attachments.get!( :my_file, true ) 
      data.should_not be_nil
      data.should_not be_empty
      data.should == read_binary(@file)
    end         
  end     
  
  describe 'packing all files' do 
    before(:each) do
      @attachments.add( :my_file, @file )
      @attachments.add( 'dup.png', @file )
      @pack = @attachments.pack 
    end  
    
    it 'should pack all the added files' do
      @pack.keys.sort.should == ['dup.png', 'my_file'] 
    end
   
    it 'should have correct keys for each attachment' do   
      @pack['dup.png'].keys.sort.should include( 'content_type', 'data' )
    end 
    
    it 'should have the correct mime type' do
      @pack['dup.png']['content_type'].should == 'image/png'
    end   
  end  
    
end