module CouchSpring
  class Document < DocumentBase 
    # includes any method not part of design documents:
    #   queries
    #   
    
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
      @design_document ||= 
      if design_name 
        DesignDocument.get( design_name ) || 
        DesignDocument.create(:name => design_name) ||
        DesignDocument.create!(:name => design_name)
      end
      @design_document.database = self.database
      @design_document   
    end  
            
  end
end    