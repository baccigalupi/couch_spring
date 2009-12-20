require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe CouchSpring do
  describe 'text helper methods' do
    describe 'extension' do   
      it 'should add methods to the CouchSpring module' do
        CouchSpring.should respond_to(:escape)
      end  
    end  
     
    describe 'escaping names' do 
      it 'should escape :: module/class separators with a double underscore __' do
        string = CouchSpring.escape('not::kosher')
        string.should == 'not__kosher'
      end
      
      it 'should remove non alpha-numeric, hyphen, underscores from a string' do 
        string = CouchSpring.escape('&not_!kosher*%')
        string.should == 'not_kosher'
      end        
    end
    
    describe 'paramify_url' do
      it 'should build a query filled url from a base url and a params hash' do 
        url = CouchSpring.paramify_url( 'http://localhost:5984', {:gerbil => true, :keys => 'you_know_it'} )
        url.should match(/\?/)
        url.should match(/&/)
        url.should match(/keys=you_know_it/)
        url.should match(/gerbil=true/)
      end  
    end     
  end
end   