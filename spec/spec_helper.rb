$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rubygems'
require 'json'
require 'couch_spring'

# Set Adapter here to use with individual test runs 
# rake spec doesn't use this for whatever reason
# CouchSpring.set_http_adapter( 'TyphoeusAdapter')

require 'spec'
require 'spec/autorun'

Spec::Runner.configure do |config|
  
end
