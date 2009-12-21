require 'typhoeus'

module CouchSpring
  module TyphoeusAdapter
    Typhoeus.init_easy_object_pool
  
    def self.request
      easy = Typhoeus.get_easy_object # http client pooling
      response_array = yield( easy ) 
      response = process_response( response_array )
      Typhoeus.release_easy_object(easy)  # releasing the http client to the pool 
      response 
    end 
  
    def self.process_response( response_array )
      code, response = response_array 
      response = JSON.parse( response ) 
      do_exception( code, response ) unless [200, 201].include?( code )
      response  
    end
  
    def self.do_exception( code, response )
      exception = case code 
      when 404
        CouchSpring::ResourceNotFound
      when 419 
        CouchSpring::RequestFailed 
      else
        Exception   
      end
      raise exception, "HTTP Code - #{code}: #{response['reason']}"  
    end     
  
    def self.get(uri, headers={}, streamable=false)
      request do |easy|
        easy.url      = uri
        easy.headers  = headers unless headers.empty?
        easy.perform
        [easy.response_code, easy.response_body]
      end    
    end

    def self.post(uri, data, headers={}) 
      request do |easy|
        easy.url      = uri 
        easy.method   = :post
        easy.headers  = headers unless headers.empty?
        easy.params   = data.to_json if data
        easy.perform
        [easy.response_code, easy.response_body]
      end
    end

    def self.put(uri, data, headers={})
      request do |easy|
        easy.url      = uri 
        easy.method   = :put
        easy.headers  = headers unless headers.empty?
        easy.params   = data.to_json if data
        easy.perform
        [easy.response_code, easy.response_body]
      end
    end

    def self.delete(uri, headers={}) 
      request do |easy|
        easy.url      = uri 
        easy.method   = :delete
        easy.headers  = headers unless headers.empty?
        easy.perform
        [easy.response_code, easy.response_body]
      end
    end

    def self.copy(uri, headers) 
      request do |easy|
        easy.url      = uri 
        easy.method   = :copy
        easy.headers  = headers unless headers.empty?
        easy.perform
        [easy.response_code, easy.response_body]
      end
    end    
  end   
end           