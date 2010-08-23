module CouchSpring
  class Server
    DEFAULT_DOMAIN = "127.0.0.1"
    DEFAULT_PORT = "5984"
    DEFAULT_PROTOCOL = 'http'
    
    attr_accessor :protocol, :domain, :port, :uuids, :uuid_limit, :username, :password
    
    def initialize(opts={})
      opts = Gnash.new(opts) unless opts.empty?
      self.protocol =         opts[:protocol] || DEFAULT_PROTOCOL
      self.username =         opts[:username] ? CGI.escape(opts[:username]) : nil
      self.password =         opts[:password] ? CGI.escape(opts[:password]) : nil
      self.domain =           opts[:domain] ? CGI.escape(opts[:domain]) : nil
      self.port =             opts[:port]
      self.uuid_limit =       (opts[:uuid_limit] || 1000).to_i
    end 
    
    def uri( reload = false)
      unless @uri || reload
        credentials = username ? "#{username}:#{password}@" : nil
        unless domain
          self.domain = DEFAULT_DOMAIN
          self.port ||= DEFAULT_PORT
        end
        port = self.port ? ":#{self.port}" : nil
        @uri = "#{protocol}://#{credentials}#{domain}#{port}"
      end
      @uri
    end
    
    def inspect
      "#<CouchSpring::Server:#{object_id} uri=\"#{uri}\">"
    end
    
    def ==( other_server )
      other_server.uri == uri
    end 
    
        # GET the welcome message
    def info
      CouchSpring.get "#{uri}/"
    end 
    
    def config 
      CouchSpring.get "#{uri}/_config"
    end
    
    def stats( group=nil, key=nil )
      if group && key
        CouchSpring.get "#{uri}/_stats/#{CGI.escape(group)}/#{CGI.escape(key)}" 
      else  
        CouchSpring.get "#{uri}/_stats"
      end  
    end    
    
    # Restart the CouchSpring instance
    def restart!
      CouchSpring.post "#{uri}/_restart"
    end
    
    # Retrive an unused UUID from CouchSpring. Server instances manage caching a list of unused UUIDs.
    def next_uuid( limit = uuid_limit )
      self.uuids ||= []
      if uuids.empty?
        get_uuids( limit )
      end
      uuids.pop
    end
    
    def get_uuids( limit = uuid_limit ) 
      self.uuids = CouchSpring.get("#{uri}/_uuids?count=#{limit}")["uuids"]
    end               

    # Lists all database names on the server
    def database_names
      names = CouchSpring.get( "#{uri}/_all_dbs" )
    end
    
    def databases
      dbs = [] 
      database_names.each do |name|
        dbs << Database.new( :name => name, :server => self )
      end
      dbs  
    end  
  end
  
  # configures CouchSpring to hold a number of servers for use in the application
  module ServerConfig
    # Cache of CouchSpring Servers used by Aqua. Each is identified by its namespace.
    #
    # @api private
    def servers
      @servers ||= Gnash.new
    end 
    
    # Clears the cached servers. So far this is most useful for testing. 
    # API will depend on usefulness outside this. 
    #
    # @api private
    def clear_servers
      @servers = Gnash.new
    end 
  
    # Getter/setter for pooling servers
    #
    def server( name = :default, new_server = nil, opts = {} )
      if new_server && new_server.is_a?( Server )
        servers[name] = new_server
      elsif found = servers[name] 
        found
      else
        add_server(name, opts)
      end   
    end
    
    def add_server( name, opts )
      found = (name.to_sym == :default) ? server_from_yaml : server_from_yaml(name)
      if found 
        opts = (name.to_sym == :default) ? from_yaml : from_yaml(name)
        Database.create!( :name => opts[:database], :server => found )
        servers[name] = found
      else
        servers[name] = Server.new( opts )
      end
    end
    
    
  end # Servers module
  
  extend ServerConfig
end # CouchSpring     