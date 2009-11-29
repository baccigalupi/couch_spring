require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe CouchDB do
 describe 'configuration' do
    it 'should not raise an error loading the default adapter' do 
      lambda{ CouchDB.set_http_adapter }.should_not raise_error
    end
  
    it 'should add rest methods to the Aqua module' do
      CouchDB.set_http_adapter
      CouchDB.should respond_to(:get)
    end  
    
    describe 'manual loading of an alternate library' do
      # TODO: when there is an alternate library
    end         
 end
end    
  