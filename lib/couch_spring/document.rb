module CouchSpring
  class Document < DocumentBase
    def self.design_name
      @design_name ||= self.to_s
    end

    def self.design_name=( name )
      @design_name = name
    end

    # Finds or creates design document based on
    # @api semi-private
    def self.design_document( reload=false )
      @design_document = get_design if !@design_document || reload
      @design_document
    end

    def self.get_design
      @design_document = DesignDocument.get( :name => design_name, :database => database ) ||
        DesignDocument.create!(:name => design_name, :database => database)
      _add_class_query  
      @design_document  
    end

    def self._add_class_query
      @design_document << {:name => 'all', :class_constraint => self } unless @design_document.views.keys.include?( 'all' )
    end

    # @return the number of objects of this class in the database
    def self.count
      design_document.count({})
    end

    # The class name is saved in order to be able to easily find all
    # documents of this type.
    def save( swallow_exception=true )
      self[:class_] = self.class.to_s
      super
    end
  end
end
