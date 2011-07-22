module CouchSpring
  module RestAPI
    def self.adapter=( klass )
      @adapter = klass
    end

    def self.adapter
      @adapter
    end

    @@log = false  # for debugging

    def log method, uri
      puts [method, uri, caller[1]].join(' ') if @@log
    end

    def put(uri, doc = nil)
      log :put, uri
      response = RestAPI.adapter.put( uri, doc )
    end

    def get(uri, opts={})
      log :get, uri
      response = RestAPI.adapter.get(uri, :streamable => opts[:streamable])
    end

    def post(uri, doc = nil)
      log :post, uri
      response = RestAPI.adapter.post(uri, doc)
    end

    def delete(uri)
      log :delete, uri
      response = RestAPI.adapter.delete(uri)
    end

    def copy(uri, destination)
      log :copy, uri
      response = RestAPI.adapter.copy(uri, {'Destination' => destination})
    end
  end
end
