module CouchSpring
  module Config
    def self.extended( base )
      base.module_eval do
        # AUTOLOADING ---------
        # auto loads the default http_adapter if Aqua gets used without configuring it first
        class << self     
          def method_missing( method, *args, &block )
            if @adapter.nil?
              set_http_adapter # loads up the adapter related stuff
              send( method.to_sym, *args, &block )
            else
              super
            end    
          end    
        end   
      end  
    end  
     
    # Returns a string describing the http adapter in use, or loads the default and returns a similar string
    # @return [String] A string identifier for the HTTP adapter in use
    def http_adapter
      @adapter ||= set_http_adapter
    end  

    # Sets a class variable with the library name that will be loaded.
    # Then attempts to load said library from the adapter directory.
    # It is extended into the HttpAbstraction module. Then the RestAPI which 
    # references the HttpAbstraction module is loaded/extended into Aqua
    # this makes available Aqua.get 'http:://someaddress.com' and other requests 
  
    # Loads an http_adapter from the internal http_client libraries. Right now there is only the 
    # RestClient Adapter. Other adapters will be added when people get motivated to write and submit them.
    # By default the RestClientAdapter is used, and if the CouchSpring module is used without prior configuration
    # it is automatically loaded.
    #
    # @param [optional, String] Maps to the HTTP Client Adapter module name, file name is inferred by removing the 'Adapter' suffix and underscoring the string 
    # @return [String] Name of HTTP Client Adapter module
    # @see Aqua::Store::CouchSpring::RestAPI Has detail about the required interface
    # @api public
    def set_http_adapter( module_name='RestClientAdapter' )
    
      # what is happening here:
      # strips the Adapter portion of the module name to get at the client name
      # convention over configurationing to get the file name as it relates to files in http_client/adapter
      # require the hopefully found file
      # modify the RestAPI class to extend the Rest methods from the adapter
      # add the RestAPI to Aqua for easy access throughout the library
    
      @adapter = module_name
      mod = @adapter.gsub(/Adapter/, '')
      file_name = mod.underscore
      require File.dirname(__FILE__) + "/adapters/#{file_name}"
      RestAPI.adapter = "CouchSpring::#{module_name}".constantize
      extend(RestAPI)
      @adapter  # return the adapter 
    end # set_http_adapter 
    
    def database_environments!(path=default_yaml_path)
      begin
        data = File.read(path)
      rescue
        raise ArgumentError, "Expected to find yaml file at #{path}"
      end
      Gnash.new( YAML.load( data ) )
    end
    
    def database_environments(path=default_yaml_path)
      database_environments!(path) rescue nil
    end
    
    def default_yaml_path
      couch_root = defined?(COUCH_ROOT) ? COUCH_ROOT : nil
      rail_root = defined?( RAILS_ROOT ) ? RAILS_ROOT : nil
      root = couch_root || rail_root
      default_path = File.dirname(__FILE__) + '/../../../..' 
      path = (root || default_path) + '/config/couch.yml'
      File.expand_path( path )
    end
    
    def default_repository
      couch_env = defined?(COUCH_ENV) ? COUCH_ENV : nil
      rails_env = defined?(RAILS_ENV) ? RAILS_ENV : nil
      @repository || couch_env || rails_env || 'production' 
    end
    
    def from_yaml( env = default_repository )
      database_environments[env] if database_environments
    end
    
    def database_from_yaml( env = default_repository )
      if opts = from_yaml( env )
        server = server_from_yaml(env)
        Database.new(:server => server, :name => opts[:database]) if server
      end
    end 
    
    def server_from_yaml( env = default_repository )
      if opts = from_yaml( env )
        server = Server.new(opts)
      end
    end 
    
    def repository=(env)
      @repository = env
    end      
  end # Config 
  
  extend Config  
  
end # CouchSpring   