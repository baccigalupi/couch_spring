require 'rest_client'

module CouchSpring
  module RestClientAdapter
    def self.process_result(streamable=false, &blk)
      begin
        response = yield
      rescue Exception => e
        repackage_exception e
      end
      streamable ? response : parse_json( response )    
    end
      
    def self.parse_json response
      begin
        JSON.parse( response )
      rescue Exception => e
        repackage_exception( e )
      end
    end
  
    def self.repackage_exception( e )
      message = e.message || ''
      message << ": #{e.response}" if e.respond_to? :response
      
      # this error name check and conversion was originally done with
      # metaprogramming, but an if statement was better for performance
      spring_exception = if e.message && e.message.match(/\b409\b/)
        CouchSpring::Conflict
      elsif e.is_a?(RestClient::ResourceNotFound)
        CouchSpring::ResourceNotFound
      elsif e.is_a?(RestClient::RequestTimeout)
        CouchSpring::RequestTimeout
      elsif e.is_a?(RestClient::ServerBrokeConnection)
        CouchSpring::ServerBrokeConnection
      else 
        CouchSpring::RequestFailed
      end
      
      raise spring_exception, message
    end
    
    def self.get(uri, headers={})
      process_result(headers.delete(:streamable)) do 
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