module RestAPI
  def self.adapter=( klass )
    @adapter = klass
  end
  
  def self.adapter
    @adapter
  end     
  
  def put(uri, doc = nil)
    response = RestAPI.adapter.put( uri, doc ) 
  end

  def get(uri, streamable=false) 
    response = RestAPI.adapter.get(uri)
  end

  def post(uri, doc = nil)
    response = RestAPI.adapter.post(uri, doc)
  end

  def delete(uri) 
    response = RestAPI.adapter.delete(uri)
  end

  def copy(uri, destination)
    response = RestAPI.adapter.copy(uri, {'Destination' => destination}) 
  end 

end