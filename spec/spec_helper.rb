$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rubygems'
require 'json'
require 'couch_spring'

# Set Adapter here to use with individual test runs 
# CouchSpring.set_http_adapter( 'TyphoeusAdapter')

require 'rspec'
require File.dirname(__FILE__) + "/test_helpers"

RSpec.configure do |config|
  include TestHelpers
end
