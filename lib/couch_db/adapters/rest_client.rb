require 'rest_client'

module RestClientAdapter
  def self.process_result(&blk)
    begin
      JSON.parse( yield )
    rescue Exception => e 
      ending = e.class.to_s.match(/[a-z0-9_]*\z/i)
      if e.message.match(/409\z/)
        raise CouchDB::Conflict, e.message
      else  
        begin
          error = "CouchDB::#{ending}".constantize
        rescue
          raise e
        end
        raise error, e.message 
      end     
    end    
  end  
  
  def self.get(uri, headers={}, streamable=false) 
    begin
      process_result do 
        RestClient.get(uri, headers)
      end 
    rescue Exception => e 
      if streamable
        response
      else
        raise e
      end    
    end    
  end

  def self.post(uri, hash, headers={})
    process_result do
      RestClient.post(uri, hash, headers)
    end  
  end

  def self.put(uri, hash, headers={})
    process_result do
      RestClient.put(uri, hash, headers)
    end  
  end

  def self.delete(uri, headers={})
    process_result do 
      RestClient.delete(uri, headers)
    end  
  end

  def self.copy(uri, headers)
    process_result do 
      RestClient::Request.execute(  :method   => :copy,
                                    :url      => uri,
                                    :headers  => headers) 
    end                                
  end 
end