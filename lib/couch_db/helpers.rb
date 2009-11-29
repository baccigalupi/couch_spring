module CouchDB
  module Helpers 
    # TEXT HELPERS ================================================
  
    # This comes from the CouchRest Library and its licence applies. 
    # It is included in this library as LICENCE_COUCHREST.
    # The method breaks the parameters into a url query string.
    # 
    # @param [String] The base url upon which to attach query params
    # @param [optional Hash] A series of key value pairs that define the url query params 
    # @api semi-public
    def paramify_url( url, params = {} )
      if params && !params.empty?
        query = params.collect do |k,v|
          v = v.to_json if %w{key startkey endkey}.include?(k.to_s)
          "#{k}=#{CGI.escape(v.to_s)}"
        end.join("&")
        url = "#{url}?#{query}"
      end
      url
    end 
  
    # A convenience method for escaping a string,
    # namespaced classes with :: notation will be converted to __ 
    # all other non-alpha numeric characters besides hyphens and underscores are removed 
    #
    # @param [String] to be converted
    # @return [String] converted
    #
    # @api private
    def escape( str )
      str.gsub!('::', '__')
      str.gsub!(/[^a-z0-9\-_]/, '')
      str
    end  
  end
  
  extend Helpers
end    