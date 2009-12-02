require 'typhoeus'

module TyphoeusAdapter
  
  Typhoeus.init_easy_object_pool
  
  def self.request
    # http client pooling 
    easy = Typhoeus.get_easy_object
    # should be and exception conversion too
    response = yield( easy )
    respones = process_response( response )
    Typhoeus.release_easy_object(easy)
    response
  end 
  
  def self.process_response( response )
    # if response
  end   
  
  def self.get(uri, headers={})
    request do |easy|
      easy.url      = uri
      easy.headers  = headers unless headers.empty?
      easy.perform
      easy.response_body
    end    
  end

  def self.post(uri, data, headers={})
    request do |easy|
      easy.url      = uri 
      easy.method   = :post
      easy.headers  = headers unless headers.empty?
      easy.params   = data 
      easy.perform
      easy.response_body
    end
  end

  def self.put(uri, data, headers={})
    request do |easy|
      easy.url      = uri 
      easy.method   = :put
      easy.headers  = headers unless headers.empty?
      easy.params   = data 
      easy.perform
      easy.response_body
    end
  end

  def self.delete(uri, headers={}) 
    request do |easy|
      easy.url      = uri 
      easy.method   = :delete
      easy.headers  = headers unless headers.empty?
      easy.perform
      easy.response_body
    end
  end

  def self.copy(uri, headers) 
    request do |easy|
      easy.url      = uri 
      easy.method   = :copy
      easy.headers  = headers unless headers.empty?
      easy.perform
      easy.response_body
    end
  end    
end  