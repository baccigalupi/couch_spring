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
      @design_document = nil if reload 
      @design_document ||= get_design
      @design_document.database = self.database  # todo: is this the right place
      _add_class_query 
      @design_document   
    end 
    
    def self.get_design 
      DesignDocument.get( design_name ) || 
      DesignDocument.create(:name => design_name) ||
      DesignDocument.create!(:name => design_name)
    end  
    
    def self._add_class_query
      @design_document << {:name => 'all', :class_constraint => self } unless @design_document.views.keys.include?( 'all' )
    end
    
    # The class name is saved in order to be able to easily find all
    # documents of this type.
    def save( swallow_exception=true ) 
      self[:_class] = self.class.to_s
      super
    end      
            
  end
end    