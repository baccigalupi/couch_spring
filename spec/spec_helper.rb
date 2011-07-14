$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rubygems'
require 'json'
require 'couch_spring'

require 'rspec'
require 'rspec/autorun'

require File.dirname(__FILE__) + "/test_helpers"

RSpec.configure do |config|
  include TestHelpers
end
