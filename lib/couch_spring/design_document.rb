module CouchSpring
  class DesignDocument < DocumentBase
    class MissingClass < TypeError; end

    # In the design document the name is the same as the id. That way initialization can
    # include a name parameter, which will change the id, and therefore the address of the
    # document. This method returns the id.
    # @return [String] id for document
    # @api public
    def name
      id
    end

    # Sets the id and is an alias for id=.
    # @param [String] Unique identifier
    # @return [String] Escaped identifier
    # @api public
    def name=( n )
      self.id = ( n )
    end

    def initialize( hash={} )
      hash = Gnash.new( hash ) unless hash.empty?
      self.id = hash.delete(:name) if hash[:name]
      super( hash )
    end

    # couchdb database url for the design document
    # @return [String] representing CouchSpring uri for document
    # @api public
    def uri
      raise ArgumentError, 'DesignDocument must have a name' if name.nil? || name.empty?
      database.uri + '/_design/' + name
    end

    # Updates the id and rev after a design document is successfully saved. The _design/
    # portion of the id has to be stripped.
    # @param [Hash] Result returned by CouchSpring document save
    # @api private
    def update_version( result )
      self.id     = result['id'].gsub(/\A_design\//, '')
      self.rev    = result['rev']
    end

    def self.uri_for( name )
      "#{database.uri}/_design/#{CGI.escape(name)}"
    end

    # VIEWS --------------------

    # An array of indexed views for the design document.
    # @return [Array]
    # @api public
    def views
      self[:views] ||= Gnash.new
    end

    def view_names
      views.keys
    end

    # Adds or updates a view with the given options
    #
    # @param [String, Hash] Name of the view, or options hash
    # @option arg [String] :name The view name, required
    # @option arg [String] :map Javascript map function, optional
    # @option arg [String] :reduce Javascript reduce function, optional
    #
    # @return [Gnash] Map/Reduce mash of javascript functions
    #
    # @example
    #   design_doc << 'attribute_name'
    #   design_doc << {:name => 'attribute_name', :map => 'function(doc){ ... }'}
    #
    # @api public
    def <<( arg )
      # handle different argument options
      if [String, Symbol].include?( arg.class )
        view_name = arg
        opts = {}
      elsif arg.class.ancestors.include?( Hash )
        opts = Gnash.new( arg )
        view_name = opts.delete( :name )
        raise ArgumentError, 'Option must include a :name that is the view\'s name' unless view_name
      else
        raise ArgumentError, "Must be a string or Hash like object of options"
      end

      # build the map/reduce query
      map =     opts[:map]
      reduce =  opts[:reduce]
      views # to initialize self[:views]
      self[:views][view_name] = {
        :map => map || build_map( view_name, opts[:class_constraint] ),
      }
      self[:views][view_name][:reduce] = reduce if reduce
      self[:views][view_name]
    end

    alias :add :<<

    def add!( arg )
      self << arg
      save!
    end

    private
      # Builds a generic map assuming that the view_name is the name of a document attribute.
      # @param [String, Symbol] Name of document attribute
      # @param [Class, String] Optional constraint on to limit view to a given class
      # @return [String] Javascript map function
      #
      # @api private
      def build_map( view_name, class_constraint=nil )
        constraints = []
        if view_name
          constraints << "doc['#{view_name}']"
          emit_key = "doc['#{view_name}']"
        else
          emit_key = "doc['_id']"
        end

        if class_constraint.class == Class
          constraints << "doc['class_'] == '#{class_constraint}'"
        elsif class_constraint.class == String
          constraints << class_constraint
        end

        "function(doc) {
          if (#{constraints.join(' && ')}){
            emit( #{emit_key}, 1 );
          }
        }"
      end

    public

    # Things to implement ...
    # group=true Version 0.8.0 and forward
    # group_level=int
    # also, the way this is paginating is inefficient, see couchdb wiki
    def raw_query( view_name, opts={} )
      opts = Gnash.new( opts ) unless opts.empty?
      doc_class = opts[:document_class]

      params = []
      params << 'include_docs=true' unless (opts[:select] && opts[:select] != 'all' || opts[:reduce])


      # TODO: this is according to couchdb really inefficent with large sets of data.
      # A better way would involve, using start and end keys with limit. But this
      # is a really hard one to figure with jumping around to different pages
      params << "skip=#{opts[:offset]}" if opts[:offset]
      params << "limit=#{opts[:limit]}" if opts[:limit]
      params << "key=#{opts[:equals]}" if opts[:equals]
      if opts[:order].to_s == 'desc' || opts[:order].to_s == 'descending'
        desc = true
        params << "descending=true"
      end
      if opts[:range] && opts[:range].size == 2
        params << "startkey=#{opts[:range][desc == true ? 1 : 0 ]}"
        params << "endkey=#{opts[:range][desc == true ? 0 : 1]}"
      end

      query_uri = "#{uri}/_view/#{CGI.escape(view_name.to_s)}?"
      query_uri << params.join('&')

      result = CouchSpring.get( query_uri )
      ResultSet.new( result, doc_class )
    end

    def query( view_name, opts={} )
      raw_docs = raw_query( view_name, opts )
      docs = raw_docs.map do |raw_doc|
        begin
          klass = raw_doc['class_'].constantize
        rescue
          raise MissingClass, "#{raw_doc['class_']} class not found. Maybe this class name has been changed. Or maybe you meant to use the design document's #raw_query method to return hashes instead of objects."
        end
        klass.new(raw_doc)
      end
    end

    # calculation queries, reductions ...
    # -----------------------------------

    # @api private
    # adds the view if it doesn't exist
    def reduced_query!( reduce_type, index, opts )
      view =  "#{index}_#{reduce_type}"
      reduction = opts[:reduce]
      # unless view_names.include?( view )
        add!(
          :name => view,
          :map => opts[:map] || build_map(nil, opts),
          :reduce => reduction
        )
      # end

      # todo: extract/merge with #query ?
      query_uri = "#{uri}/_view/#{CGI.escape(view.to_s)}"
      params = []
      query_uri << "?" << params.join('&') unless params.empty?

      result = CouchSpring.get( query_uri )
      if result['rows'].empty?
        nil
      else
        result['rows'].first['value']
      end
    end

    # @api semi-public
    def count( opts, index = :all )
      opts = Gnash.new(opts)
      opts[:map] ||= "
        function(doc) {
          emit(doc['_id'], 1);
        }"
      opts[:reduce] ||= "
        function (key, values, rereduce) {
            return sum(values);
        }"
      reduced_query!(:count, index, opts ).to_i
    end

    # @api semi-public
    def sum( index, opts={} )
      opts = Gnash.new(opts)
      opts[:reduce] = "
        function (keys, values, rereduce) {
          var key_values = []
          keys.forEach( function(key) {
            key_values[key_values.length] = key[0]
          });
          return sum( key_values );
        }" unless opts[:reduce]
      reduced_query!(:sum, index, opts)
    end

    def average( index, opts={} )
      sum(index, opts) / count(index, opts).to_f
    end

    alias :avg :average

    def min( index, opts={} )
      opts = Gnash.new(opts)
      opts[:reduce] ||= "
        function (keys, values, rereduce) {
          var key_values = []
          keys.forEach( function(key) {
            key_values[key_values.length] = key[0]
          });
          return Math.min.apply( Math, key_values ); ;
        }"
      reduced_query!(:min, index, opts)
    end

    alias :minimum :min

    def max( index, opts={} )
      opts = Gnash.new(opts)
      opts[:reduce] ||= "
        function (keys, values, rereduce) {
          var key_values = []
          keys.forEach( function(key) {
            key_values[key_values.length] = key[0]
          });
          return Math.max.apply( Math, key_values ); ;
        }"
      reduced_query!(:max, index, opts)
    end

    alias :maximum :max

  end
end
