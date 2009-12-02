# Pick your json poison. Just make sure that in adds the JSON constant
unless defined?(JSON)
  begin
    require 'json'
  rescue LoadError
    raise LoadError, "JSON constant not found. Please install a JSON library"
  end  
end  

require 'cgi'

dir = File.dirname(__FILE__) 
require dir + "/couch_db/support/string"
require dir + "/couch_db/support/gnash"
require dir + "/couch_db/rest_api"

module CouchDB
  class ResourceNotFound      < IOError; end
  class RequestFailed         < IOError; end
  class RequestTimeout        < IOError; end
  class ServerBrokeConnection < IOError; end
  class Conflict              < IOError; end  
end  

# CouchDB extensions and sub-modules/classes
require dir + "/couch_db/config"
require dir + "/couch_db/helpers"
require dir + "/couch_db/server"
require dir + "/couch_db/database"
require dir + "/couch_db/document"

       