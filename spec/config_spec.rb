require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe CouchSpring do
 describe 'configuring adapter' do
    after(:all) do
      CouchSpring.set_http_adapter( 'RestClientAdapter')
    end
      
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
 
 describe 'configure the database' do
   describe 'default yaml path' do 
     it 'should default to COUCH_ROOT + "/config/couch.yml"' do
       COUCH_ROOT = File.dirname(__FILE__)
       RAILS_ROOT = '/goober' 
       CouchSpring.default_yaml_path.should == File.dirname(__FILE__) + '/config/couch.yml'
     end
     
     it 'should default to RAILS_ROOT + "/config/couch.yml"' do
       COUCH_ROOT = nil
       RAILS_ROOT = File.dirname(__FILE__) 
       CouchSpring.default_yaml_path.should == File.dirname(__FILE__) + '/config/couch.yml'
     end
     
     it 'should not freak out if RAILS_ROOT is not defined' do
       RAILS_ROOT = nil
       lambda { CouchSpring.default_yaml_path }.should_not raise_error
     end
     
     it 'should provide an alternate default path if RAILS_ROOT is not defined' do
       CouchSpring.default_yaml_path.should == File.expand_path( File.dirname(__FILE__) + "../../../../config/couch.yml" )
     end
   end
   
   describe 'database environments' do
     it 'should use the file found at the default configuration' do
       RAILS_ROOT = File.dirname(__FILE__)
       CouchSpring.database_environments.class.should == Gnash
       CouchSpring.database_environments[:production][:database].should == 'couch_spring_for_go'
     end
     
     it 'should find database configuration at path provided' do
       RAILS_ROOT = nil
       config = CouchSpring.database_environments!(File.dirname(__FILE__) + '/config/alt.yml')
       config.class.should == Gnash   
       config[:production][:database].should == 'couch_spring_alt_the_way'
     end
     
     it '! method should raise a comprehensible exception when the yaml file is not found' do
       RAILS_ROOT = nil
       lambda do
         CouchSpring.database_environments!('/not_here.yml')
       end.should raise_error( ArgumentError, 'Expected to find yaml file at /not_here.yml')
     end 
     
     it 'non ! method should return nil when path is not found' do
       RAILS_ROOT = nil
       CouchSpring.database_environments('/not_here.yml').should be_nil
     end
   end
   
   describe 'default repository' do
     before do
       RAILS_ROOT = File.dirname(__FILE__)
     end 
     
     it 'should default to COUCH_ENV' do
       COUCH_ENV = 'test'
       RAILS_ENV = 'development'
       CouchSpring.default_repository.should == 'test'
     end
     
     it 'should fall back on RAILS_ENV' do
       COUCH_ENV =  nil
       RAILS_ENV = 'test'
       CouchSpring.default_repository.should == 'test'
     end
     
     it 'should otherwise default to production' do
       RAILS_ENV = nil
       CouchSpring.default_repository.should == 'production'
     end
     
     it 'should be customizable' do
       CouchSpring.repository = 'staging'
       CouchSpring.default_repository.should == 'staging'
     end
   end
 
   describe 'database url' do
     before do
       CouchSpring.repository = 'test'
       COUCH_ROOT = File.dirname(__FILE__)
     end
     
     it 'should apply the default repository to the database environments' do
       CouchSpring.database_url.should include 'couch_spring_test'
     end
     
     it 'should default to http protocol' do
       CouchSpring.database_url.should include 'http://'
     end
     
     it 'should include the protocol from yaml' do
       CouchSpring.repository = 'production'
       CouchSpring.database_url.should include 'https://'
     end
     
     it 'should include the username and password when provided' do
       CouchSpring.repository = 'production'
       CouchSpring.database_url.should include 'kane:password'
     end
     
     it 'should not include any credential stuff when not provided' do
       CouchSpring.repository = 'test'
       CouchSpring.database_url.should_not include '@'
     end
     
     it 'should include an alternate repository env' do 
       CouchSpring.database_url(:production).should include 'couch_spring_for_go'
     end
     
     it 'should return nil if repository is not found' do
       RAILS_ROOT = nil
       CouchSpring.database_url(:production) == nil
     end
   end
 end
end    
  