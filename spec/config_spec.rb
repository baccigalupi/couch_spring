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
      pending('could not get Typhoes working, so not relevant until there is an alternative')
      CouchSpring.set_http_adapter( 'TyphoeusAdapter')
      CouchSpring.http_adapter.should == 'TyphoeusAdapter'
    end         
  end            
 
  describe 'configure the database' do
    describe 'default yaml path' do 
      it 'should default to COUCH_ROOT + "/config/couch.yml"' do
        capturing_stderr do
          COUCH_ROOT = File.dirname(__FILE__)
          RAILS_ROOT = '/goober' 
        end
        CouchSpring.default_yaml_path.should == File.expand_path( File.dirname(__FILE__) + '/config/couch.yml' )
      end
      
      it 'should default to RAILS_ROOT + "/config/couch.yml"' do
        capturing_stderr do
          COUCH_ROOT = nil
          RAILS_ROOT = File.dirname(__FILE__) 
        end
        CouchSpring.default_yaml_path.should == File.expand_path( File.dirname(__FILE__) + '/config/couch.yml' )
      end
      
      it 'should not freak out if RAILS_ROOT is not defined' do
        capturing_stderr do
          RAILS_ROOT = nil
        end
        lambda { CouchSpring.default_yaml_path }.should_not raise_error
      end
      
      it 'should provide an alternate default path if RAILS_ROOT is not defined' do
        CouchSpring.default_yaml_path.should == File.expand_path( File.dirname(__FILE__) + "../../../../config/couch.yml" )
      end
    end
   
    describe 'database environments' do
      it 'should use the file found at the default configuration' do
        capturing_stderr{ RAILS_ROOT = File.dirname(__FILE__) }
        CouchSpring.database_environments.class.should == Gnash
        CouchSpring.database_environments[:production][:database].should == 'couch_spring_for_go'
      end
      
      it 'should find database configuration at path provided' do
        capturing_stderr{ RAILS_ROOT = nil }
        config = CouchSpring.database_environments!(File.dirname(__FILE__) + '/config/alt.yml')
        config.class.should == Gnash   
        config[:production][:database].should == 'couch_spring_alt_the_way'
      end
      
      it '! method should raise a comprehensible exception when the yaml file is not found' do
        capturing_stderr { RAILS_ROOT = nil }
        lambda do
          CouchSpring.database_environments!('/not_here.yml')
        end.should raise_error( ArgumentError, 'Expected to find yaml file at /not_here.yml')
      end 
      
      it 'non ! method should return nil when path is not found' do
        capturing_stderr { RAILS_ROOT = nil }
        CouchSpring.database_environments('/not_here.yml').should be_nil
      end
    end
   
    describe 'default repository' do
      before do
        capturing_stderr do
          RAILS_ROOT = File.dirname(__FILE__)
        end
      end 
      
      it 'should default to COUCH_ENV' do
        capturing_stderr do
          COUCH_ENV = 'test'
          RAILS_ENV = 'development'
        end
        CouchSpring.default_repository.should == 'test'
      end
      
      it 'should fall back on RAILS_ENV' do
        capturing_stderr do
          COUCH_ENV =  nil
          RAILS_ENV = 'test'
        end
        CouchSpring.default_repository.should == 'test'
      end
      
      it 'should otherwise default to production' do
        capturing_stderr do
          RAILS_ENV = nil
        end
        CouchSpring.default_repository.should == 'production'
      end
      
      it 'should be customizable' do
        CouchSpring.repository = 'staging'
        CouchSpring.default_repository.should == 'staging'
      end
    end
   
    describe 'server from yaml' do
      before do
        capturing_stderr do
          RAILS_ROOT = nil
          COUCH_ROOT = File.dirname(__FILE__)
        end
      end
      
      it 'should default to http protocol' do
        CouchSpring.server_from_yaml(:test).protocol.should include 'http'
      end
      
      it 'should include the protocol from yaml' do
        CouchSpring.server_from_yaml(:production).protocol.should include 'https'
      end
      
      it 'should include the username and password when provided' do
        server = CouchSpring.server_from_yaml(:production)
        server.username.should == 'kane'
        server.password.should == 'password'
      end
      
      it 'should use the port if provided' do
        CouchSpring.server_from_yaml(:test).port.should == 5984
        CouchSpring.server_from_yaml(:cloudant).port.should == nil
      end
      
      it 'should return nil if repository is not found' do
        capturing_stderr { COUCH_ROOT = nil }             
        CouchSpring.server_from_yaml(:production) == nil
      end
    end
 
    describe 'database url' do
      before do
        capturing_stderr { COUCH_ROOT = File.dirname(__FILE__) }
      end
      
      it 'should include the server uri' do
        CouchSpring.database_from_yaml(:test).server.should == CouchSpring.server_from_yaml(:test)
      end
      
      it 'should apply the default repository to the database environments' do
        CouchSpring.database_from_yaml(:test).uri.should include 'couch_spring_test'
      end
      
      it 'should include an alternate repository env' do 
        CouchSpring.database_from_yaml(:production).uri.should include 'couch_spring_for_go'
      end
      
      it 'should return nil if repository is not found' do
        capturing_stderr { COUCH_ROOT = nil }
        CouchSpring.database_from_yaml(:production) == nil
      end
    end
  end
end    
  