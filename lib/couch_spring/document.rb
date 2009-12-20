module CouchSpring
  class Document < Gnash
    # Initializes a new storage document. 
    # 
    # @param [Hash, Gnash]
    # @return [Aqua::Storage] a Hash/Gnash with some extras
    #
    # @api public
    def initialize( hash={} )
      hash = Gnash.new( hash ) # to prevent the hash being consumed
      hash_id = hash.delete(:id) || hash.delete(:_id)
      self.id = hash_id if hash_id
      hash.delete(:rev) # must feed it _rev if looking to change the rev
      
      # feed the rest of the hash to the super 
      super( hash )      
    end
    
    # Gets the document id. In this engine id and _id are different data. The main reason for this is that
    # CouchSpring needs a relatively clean string as the key, where as the user can assign a messy string to
    # the id. The user can continue to use the messy string since the engine also has access to the _id.
    # 
    # @return [String]
    #
    # @api public 
    def id
      self[:id]
    end
    
    # Allows the id to be set. If the id is changed after creation, then the CouchSpring document for the old
    # id is deleted, and the _rev is set to nil, making it a new document. The id can only be a string (right now).
    #
    # @return [String, false] Will return the string it received if it is indeed a string. Otherwise it will
    # return false.
    #
    # @api public 
    def id=( str )
      if str.respond_to?(:match)
        escaped = CGI.escape( str )
        self[:id] = str
        self[:_id] = escaped 
        str 
      end 
      # # CLEANUP: do a bulk delete request on the old id, now that it has changed
      # delete(true) if !new? && escaped != self[:_id]      
    end
    
    # Returns CouchSpring document revision identifier.
    # 
    # @return [String]
    #
    # @api semi-public
    def rev
      self[:_rev]
    end

    protected 
      def rev=( str )
        self[:_rev] = str
      end   
    public
    
    # Returns true if the document has never been saved or false if it has been saved.
    # @return [true, false]
    # @api public
    def new?
      !rev
    end
    alias :new_document? :new?
    
    # Getter setter for default of custom database per Document class
    # 
    # @return [CouchSpring::Database]
    #
    # @api public
    def self.database( db=nil )
      if db
        @database = 
        if db.is_a?( Database ) 
          db
        else
          Database.new(:server => CouchSpring.server, :name => db)
        end  
      end
      @database ||= Database.new(:server => CouchSpring.server)
    end
    
    # Sets default database per instance. Defaults to class's database
    # 
    # @return [CouchSpring::Database]
    #
    # @api public 
    def database
      @database ||= self.class.database
    end 
    
    # Setter for the database per instance. Used to override default above. 
    #
    # @return [CouchSpring::Database]
    #
    # @api public
    def database=( db )
      @database = 
      if db.is_a?( Database ) 
        db
      else
        Database.new(:server => self.class.database.server, :name => db)
      end  
    end 
    
    # couchdb database url for this document
    # @return [String] representing CouchSpring uri for document 
    # @api public
    def uri
      "#{database.uri}/#{ensure_id}"
    end  
  
  
    # gets a uuid from the server if one doesn't exist, otherwise escapes existing id.
    # @api private
    def ensure_id
      self[:_id] = ( id ? escape_doc_id : database.server.next_uuid )
    end 
    
    # Escapes document id. Different strategies for design documents and normal documents.
    # @api private
    def escape_doc_id 
      CGI.escape( id )
    end 
    
    # Saves a Document instance to CouchSpring database. 
    #
    # @param [optional true, false] Determines whether the document is cached for bulk saving later. true will cause it to be defered. Default is false.
    # @return [CouchSpring::Document, false] Will return false if the document is not saved. Otherwise it will return the Aqua::Storage object.
    #
    # @api public
    def save( swallow_exception=true )
      # prep the document
      ensure_id
      self[:_attachments] = attachments.pack unless attachments.empty?
      
      begin 
        result = CouchSpring.put( uri, self )
        if result && result['ok']
          update_version( result )
          result = self
        end  
        result 
      rescue Exception => e
        if swallow_exception
          false
        else
          raise e
        end    
      end    
    end
    
    def save!
      save( false )
    end
        
    # Updates the id and rev after a document is successfully saved.
    # @param [Hash] Result returned by CouchSpring document save
    # @api private
    def update_version( result ) 
      self.id     = result['id']
      self.rev    = result['rev']
    end
    
    # Initializes a new storage document and saves it without raising any errors
    # 
    # @param [Hash, Gnash]
    # @return [CouchSpring::Document, false] On success it returns an aqua storage object. On failure it returns false.
    # 
    # @api public
    def self.create( hash )
      doc = new( hash )
      doc.save
    end

    # Initializes a new storage document and saves it raising any errors.
    # 
    # @param [Hash, Gnash]
    # @return [CouchSpring::Document] On success it returns an aqua storage object. 
    # @raise Any of the CouchSpring exceptions
    # 
    # @api public
    def self.create!( hash )
      doc = new( hash )
      doc.save!
    end
    
    # reloads self from CouchSpring database
    # @return [Document] representing CouchSpring data
    # @api public
    def reload
      self.replace( CouchSpring.get( uri ) )
    end   
    
    # Gets a document from the database based on id
    # @param [String] id 
    # @return [Hash] representing the CouchSpring data
    # @api public
    def self.get( id )
      resource = begin # this is just in case the developer has already escaped the name
        CouchSpring.get( "#{database.uri}/#{CGI.escape(id)}" )
      rescue
        CouchSpring.get( "#{database.uri}/#{id}" )  
      end
      new( resource ) 
    end   
    
    # Returns true if a document exists at the CouchSpring uri for this document. Otherwise returns false
    # @return [true, false]
    # @api public
    def exists?
      begin 
        CouchSpring.get uri
        true
      rescue
        false
      end    
    end
    
    alias :exist? :exists?
    
    # Gets revision history, which is needed by Delete to remove all versions of a document
    # 
    # @return [Array] Containing strings with revision numbers
    # 
    # @api semi-private
    def revisions
      active_revisions = []
      begin
        hash = CouchSpring.get( "#{uri}?revs_info=true" )
      rescue
        return active_revisions
      end    
      hash['_revs_info'].each do |rev_hash|
        active_revisions << rev_hash['rev'] if ['disk', 'available'].include?( rev_hash['status'] )
      end
      active_revisions  
    end       
    
    # Deletes an document from CouchSpring. Delete can be deferred for bulk saving/deletion.
    #
    # @param [optional true, false] Determines whether the document is cached for bulk saving later. true will cause it to be defered. Default is false.
    # @return [String, false] Will return a json string with the response if successful. Otherwise returns false.
    #
    # @api public
    def delete( key=nil, all_revs=false )
      if key
        super(key) # still want it to act like a hash
      else
        raise ArgumentError, 
          'Document has no revision and can\'t be deleted. Maybe you want to delete all revisions with #delete!' if rev.nil? && !all_revs
        if all_revs
          revisions.each do |rev_id| 
            CouchSpring.delete( "#{uri}?rev=#{rev_id}" ) rescue nil
          end
        elsif rev
          result = CouchSpring.delete( "#{uri}?rev=#{rev}") rescue false
          result && result['ok'] 
        end 
      end
    end      
    
    # Deletes an document from CouchSpring. The ! version will kill previous version of the document in addition to the current revision.
    #
    # @return [true, false] 
    #
    # @api public
    def delete!
      delete( nil, true ) 
    end
    
    # Retrieves an attachment when provided the document id and attachment id, or the combined id 
    #
    # @return [Tempfile]
    #
    # @api public
    def self.attachment( document_id, attachment_id )
      new( :id => document_id ).attachments.get!( attachment_id )
    end   
    
    # Hash of attachments, keyed by name
    # @params [Document] Document object that is self
    # @return [Hash] Attachments keyed by name
    # 
    # @api public
    def attachments
      @attachments ||= Attachments.new( self )
    end      
                      
  end
end    