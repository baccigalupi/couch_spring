module CouchSpring
  class Database
    attr_accessor :server, :name, :state

    DEFAULT_NAME = 'ruby'

    # Builds a CouchSpring database representation from a name. It does not actually create a database on couchdb.
    # It does not ensure that the database actually exists either. Just creates a ruby representation
    # of a ruby database interface.
    #
    # @param [optional String] Name of database. If not provided server namespace will be used as database name.
    # @param [optional Hash] Options for initialization. Currently the only option is :server which must be either a CouchSpring server object or a symbol representing a server stored in the CouchSpring module.
    # @return [Database] The initialized object
    #
    # @api public
    def initialize( *args )
      self.state = :new
      if args.size > 1
        opts = Gnash.new(args.last)
        opts[:name] = args.first
      else
        opts = Gnash.new(args.last)
      end
      self.name = CouchSpring.escape( (opts[:name] || 'ruby').to_s )
      server = opts[:server] || CouchSpring.server
      self.server = server.is_a?( Server ) ? server : CouchSpring.server( server )
    end

    def uri
      "#{server.uri}/#{name}"
    end

    def ==( other_db )
      other_db.is_a?(Database) && other_db.uri == uri
    end
    
    def ensure_state
      if state.nil?
        begin
          CouchSpring.get( uri )
          self.state = :saved
        rescue CouchSpring::ResourceNotFound
          self.state = :new
        end
      end
      state
    end
    
    # Tracks and checks whether the database is new or saved to the server already.
    #
    # @return [true, false] depending on whether the database already exists in CouchSpring land
    #
    # @api public
    def new?
      ensure_state == :new
    end
    
    # Checks to see if the database exists on the couchdb server.
    #
    # @return [true, false] depending on whether the database already exists in CouchSpring land
    #
    # @api public
    def exist?
      ensure_state == :saved
    end
    alias exists? exist?

    def save( swallow_exception=true )
      begin
        CouchSpring.put( uri )
        self.state = :saved
      rescue Exception => e
        if e.message.match(/Precondition Failed/i) 
          # database already exists, no need to raise an error
          self.state = :saved
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

    # Creates a database representation and PUTs it on the CouchSpring server.
    # If successful returns a database object. If not successful in creating
    # the database on the CouchSpring server then, false will be returned.
    #
    # @see CouchSpring#initialize for option details
    # @return [Database, false] Will return the database on success, and false if it did not succeed.
    #
    # @api pubilc
    def self.create( opts={}, swallow_exception=true )
      db = new(opts)
      db = db.save( swallow_exception )
      db
    end

    # Creates a database representation and PUTs it on the CouchSpring server.
    # This version of the #create method raises an error if the PUT request fails.
    # The exception on this, is if the database already exists then the 412 HTTP code will be ignored.
    #
    # @see CouchSpring#initialize for option details
    # @return [Database] Will return the database on success.
    # @raise HttpAdapter Exceptions depending on the reason for failure.
    #
    # @api pubilc
    def self.create!( opts={} )
      create( opts, false )
    end

    # GET the database info from CouchSpring
    def info
      CouchSpring.get( uri ) rescue nil
    end
    
    # GET the database info from CouchSpring, raising an error if the database is not present
    def info!
      CouchSpring.get( uri )
    end

    # Deletes a database; use with caution as this isn't reversible.
    #
    # @return A JSON response on success. nil if the resource is not found. And raises an error if another exception was raised
    # @raise Exception related to request failure that is not a ResourceNotFound error.
    def delete
      begin
        delete!
      rescue CouchSpring::ResourceNotFound
        false
      end
    end

    # Deletes a database; use with caution as this isn't reversible. Similar to #delete,
    # except that it will raise an error on failure to find the database.
    #
    # @return A JSON response on success.
    # @raise Exception related to request failure or ResourceNotFound.
    def delete!
      response = CouchSpring.delete( uri )
      self.state = :deleted
      response
    end
    
    # options:
    # filter => filter_name
    # query_params => array_of_params
    # doc_ids => array_of_ids
    def replicate( target, opts={} )
      if [String, Symbol].include?( target.class )
        target = self.class.new(:name => target, :server => server)
      end
      
      data = {
        'source' => self.name,
        'target' => target.uri
      }
      data.merge!('continuous' => true)             if opts[:continuous]
      data.merge!('create_target' => true)          if opts[:create]
      data.merge!('cancel' => true)                 if opts[:cancel]
      data.merge!('proxy' => opts[:proxy])          if opts[:proxy]
      data.merge!('filter' => opts[:filter])        if opts[:filter]
      data.merge!('query_params' => opts[:params])  if opts[:params]
      data.merge!('doc_ids' => opts[:doc_ids])    if opts[:doc_ids]
      
      CouchSpring.post( "#{server.uri}/_replicate/", data )  
    end 
    
    def changes( since=nil)
      since_params = "?since=#{since.to_i}" if since
      CouchSpring.get( "#{uri}/_changes#{since_params}")
    end

    def compact!
      CouchSpring.post( "#{uri}/_compact")
    end

    # Query the <tt>documents</tt> view. Accepts all the same arguments as view.
    def documents(params = {})
      keys = params.delete(:keys)
      url = CouchSpring.paramify_url( "#{uri}/_all_docs", params )
      if keys
        CouchSpring.post(url, {:keys => keys})
      else
        CouchSpring.get url
      end
    end

    # Deletes all the documents in a given database
    # note: this also deletes the design doc
    def delete_all
      documents['rows'].each do |doc|
        CouchSpring.delete( "#{uri}/#{CGI.escape( doc['id'])}?rev=#{doc['value']['rev']}" ) #rescue nil
      end
    end
    
    def self.default
      new
    end
    
    def self.default!
      create!
    end

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
    #   CouchSpring.post( "#{uri}/_bulk_docs", {:docs => docs} )
    # end

  end # Database
end # CouchSpring
