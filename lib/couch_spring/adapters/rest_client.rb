require 'rest_client'

module CouchSpring
  module RestClientAdapter
    def self.process_result(streamable=false, &blk)
      begin
        response = yield
        begin
          JSON.parse( response )
        rescue Exception => e
          if streamable
            return response 
          else
            message = [e.class.to_s, e.message]
            message << e.response if e.respond_to? :response
            message = message.join(" ")
            raise CouchSpring::RequestFailed, message
          end  
        end   
      rescue Exception => e
        message = [e.class.to_s, e.message]
        message << e.response if e.respond_to? :response
        message = message.join(" ")
        ending = e.class.to_s.match(/[a-z0-9_]*\z/i)
        if e.message.match(/409\z/)
          raise CouchSpring::Conflict, message
        else  
          begin
            error = "CouchSpring::#{ending}".constantize
          rescue
            raise CouchSpring::RequestFailed, message
          end
          raise error, message
        end     
      end    
    end  
  
    def self.get(uri, streamable=false, headers={}) 
      process_result(streamable) do 
        response = RestClient.get(uri, headers)
      end 
    end

    def self.post(uri, hash, headers={}) 
      headers = {:"content-type" => "application/json"}.merge(headers)
      hash = hash.to_json if hash
      process_result do
        RestClient.post(uri, hash, headers)
      end  
    end

    def self.put(uri, hash, headers={})
      hash = hash.to_json if hash 
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
end  