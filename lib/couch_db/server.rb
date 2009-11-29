module CouchDB
  class Server
    attr_accessor :domain, :port, :uuids, :uuid_limit
    
    def initialize(opts={})
      opts = Gnash.new(opts) unless opts.empty?
      self.domain =           opts[:domain] ? CGI.escape(opts[:domain]) : '127.0.0.1'
      self.port =             opts[:port] ||    '5984'
      self.uuid_limit =       opts[:uuid_limit].to_i
    end 
    
    def uri
      "http://#{domain}:#{port}"
    end
    
    def inspect
      "#<CouchDB::Server:#{object_id} uri=\"#{uri}\">"
    end
    
    def ==( other_server )
      other_server.uri == uri
    end 
    
        # GET the welcome message
    def info
      CouchDB.get "#{uri}/"
    end 
    
    def config 
      CouchDB.get "#{uri}/_config"
    end
    
    def stats( group=nil, key=nil )
      if group && key
        CouchDB.get "#{uri}/_stats/#{CGI.escape(group)}/#{CGI.escape(key)}" 
      else  
        CouchDB.get "#{uri}/_stats"
      end  
    end    
    
    # Restart the CouchDB instance
    def restart!
      CouchDB.post "#{uri}/_restart"
    end
    
    # Retrive an unused UUID from CouchDB. Server instances manage caching a list of unused UUIDs.
    def next_uuid( limit = uuid_limit )
      self.uuids ||= []
      if uuids.empty?
        get_uuids( limit )
      end
      uuids.pop
    end
    
    def get_uuids( limit = uuid_limit ) 
      self.uuids = CouchDB.get("#{uri}/_uuids?count=#{limit}")["uuids"]
    end               

    # Lists all database names on the server
    def database_names
      names = CouchDB.get( "#{uri}/_all_dbs" )
    end
    
    def databases
      dbs = [] 
      database_names.each do |name|
        dbs << Database.new( :name => name, :server => self )
      end
      dbs  
    end  
  end
  
  # configures CouchDB to hold a number of servers for use in the application
  module ServerConfig
    # Cache of CouchDB Servers used by Aqua. Each is identified by its namespace.
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
    # @param [Hash] 
    # @opts :name The name used to store/retreive the instance 
    # @opts :server If used, sets the server key to this instance 
    def server( name = :default, new_server = nil )
      if new_server && new_server.is_a?( Server )
        servers[name] = new_server
      elsif servers[name] 
        servers[name]
      else
        servers[name] = Server.new
      end   
    end
  end # Servers module
  
  extend ServerConfig
end # CouchDB     