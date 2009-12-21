# Pick your json poison. Just make sure that in adds the JSON constant
unless defined?(JSON)
  begin
    require 'json'
  rescue LoadError
    raise LoadError, "JSON constant not found. Please install a JSON library"
  end  
end  
require 'mime/types'

require 'cgi'
require 'base64'

dir = File.dirname(__FILE__) 
require dir + "/couch_spring/support/string"
require dir + "/couch_spring/support/gnash"
require dir + "/couch_spring/rest_api"

module CouchSpring
  class ResourceNotFound      < IOError; end
  class RequestFailed         < IOError; end
  class RequestTimeout        < IOError; end
  class ServerBrokeConnection < IOError; end
  class Conflict              < IOError; end  
end  

# CouchSpring extensions and sub-modules/classes
require dir + "/couch_spring/config"
require dir + "/couch_spring/helpers"
require dir + "/couch_spring/server"
require dir + "/couch_spring/database"
require dir + "/couch_spring/document_base"
require dir + "/couch_spring/document"
require dir + "/couch_spring/design_document"
require dir + "/couch_spring/attachments"
require dir + "/couch_spring/result_set"

       