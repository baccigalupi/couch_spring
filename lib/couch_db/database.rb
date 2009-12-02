module CouchDB
  class Database 
    attr_accessor :server, :name
 
    # Builds a CouchDB database representation from a name. It does not actually create a database on couchdb.
    # It does not ensure that the database actually exists either. Just creates a ruby representation
    # of a ruby database interface.
    # 
    # @param [optional String] Name of database. If not provided server namespace will be used as database name. 
    # @param [optional Hash] Options for initialization. Currently the only option is :server which must be either a CouchDB server object or a symbol representing a server stored in the CouchDB module.
    # @return [Database] The initialized object
    # 
    # @api public
    def initialize( opts={})
      opts = Gnash.new( opts )
      self.name = CouchDB.escape( (opts[:name] || 'ruby').to_s )
      server = opts[:server] || CouchDB.server
      self.server = server.is_a?( Server ) ? server : CouchDB.server( server )
    end 
    
    def uri
      "#{server.uri}/#{name}"
    end
    
    def ==( other_db ) 
      other_db.is_a?(Database) && other_db.uri == uri
    end    
    
    def save( swallow_exception=true )
      begin
        CouchDB.put( uri )
      rescue Exception => e  
        if e.message.match(/412/) # ignore database already exists errors ...
          
        else
          if swallow_exception
            return false
          else
            raise e
          end    
        end   
      end
      self 
    end
    
    def save!
      save( false )
    end    

    # Creates a database representation and PUTs it on the CouchDB server. 
    # If successfull returns a database object. If not successful in creating
    # the database on the CouchDB server then, false will be returned.
    #
    # @see CouchDB#initialize for option details
    # @return [Database, false] Will return the database on success, and false if it did not succeed. 
    #
    # @api pubilc
    def self.create( opts={}, swallow_exception=true )
      db = new(opts)
      db.save( swallow_exception )
    end 
    
    # Creates a database representation and PUTs it on the CouchDB server. 
    # This version of the #create method raises an error if the PUT request fails. 
    # The exception on this, is if the database already exists then the 412 HTTP code will be ignored.
    #
    # @see CouchDB#initialize for option details
    # @return [Database] Will return the database on success. 
    # @raise HttpAdapter Exceptions depending on the reason for failure.
    #
    # @api pubilc
    def self.create!( opts={} ) 
      create( opts, false )
    end   
    
    # Checks to see if the database exists on the couchdb server.
    #
    # @return [true, false] depending on whether the database already exists in CouchDB land
    #
    # @api public
    def exist?
      begin 
        info 
        true
      rescue CouchDB::ResourceNotFound  
        false
      end  
    end
    alias exists? exist?  
    
    # GET the database info from CouchDB
    def info
      CouchDB.get( uri )
    end 
     
    # Deletes a database; use with caution as this isn't reversible.
    # 
    # @return A JSON response on success. nil if the resource is not found. And raises an error if another exception was raised
    # @raise Exception related to request failure that is not a ResourceNotFound error.
    def delete
      begin 
        CouchDB.delete( uri )
      rescue CouchDB::ResourceNotFound
        false
      end    
    end  
    
    # Deletes a database; use with caution as this isn't reversible. Similar to #delete, 
    # except that it will raise an error on failure to find the database.
    # 
    # @return A JSON response on success. 
    # @raise Exception related to request failure or ResourceNotFound.
    def delete!
      CouchDB.delete( uri )
    end
    
    def replicate( target, continuous=false )
      if [String, Symbol].include?( target.class )
        target = self.class.new(:name => target, :server => server)
      end
      target.save 
      data = {
        'source' => self.uri,
        'target' => target.uri
      }
      data.merge!('continuous' => true) if continuous 
      CouchDB.post( "#{server.uri}/_replicate/", data )  
    end 
    
    def changes( since=nil)
      since_params = "?since=#{since.to_i}" if since
      CouchDB.get( "#{uri}/_changes#{since_params}")
    end  
    
    def compact!
      CouchDB.post( "#{uri}/_compact")
    end       
    
    # # Query the <tt>documents</tt> view. Accepts all the same arguments as view.
    # def documents(params = {})
    #   keys = params.delete(:keys)
    #   url = CouchDB.paramify_url( "#{uri}/_all_docs", params )
    #   if keys
    #     CouchDB.post(url, {:keys => keys})
    #   else
    #     CouchDB.get url
    #   end
    # end 
    # 
    # # Deletes all the documents in a given database
    # def delete_all
    #   documents['rows'].each do |doc|
    #     CouchDB.delete( "#{uri}/#{CGI.escape( doc['id'])}?rev=#{doc['value']['rev']}" ) #rescue nil
    #   end  
    # end    
    # 
    # # BULK ACTIVITIES ------------------------------------------
    # def add_to_bulk_cache( doc ) 
    #   if server.uuid_count/2.0 > bulk_cache.size
    #     self.bulk_cache << doc 
    #   else
    #     bulk_save
    #     self.bulk_cache << doc
    #   end    
    # end
    # 
    # def bulk_save
    #   docs = bulk_cache
    #   self.bulk_cache = []
    #   CouchDB.post( "#{uri}/_bulk_docs", {:docs => docs} )
    # end      
               
  end # Database
end # CouchDB   