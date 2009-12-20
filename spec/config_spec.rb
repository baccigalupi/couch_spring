require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe CouchSpring do
 describe 'configuration' do
    it 'should not raise an error loading the default adapter' do 
      lambda{ CouchSpring.set_http_adapter }.should_not raise_error
    end
  
    it 'should add rest methods to the Aqua module' do
      CouchSpring.set_http_adapter
      CouchSpring.should respond_to(:get)
    end  
    
    it 'manual loading of an alternate library' do
      CouchSpring.set_http_adapter( 'TyphoeusAdapter')
      CouchSpring.http_adapter.should == 'TyphoeusAdapter'
    end         
 end
end    
  