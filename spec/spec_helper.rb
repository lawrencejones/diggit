ENV['RACK_ENV'] = 'test'

require 'bundler/setup'
Bundler.setup(:default, :test)

require 'rspec'
require 'pry'
require 'coach'
require 'active_support/core_ext'

Coach.require_matchers!

$LOAD_PATH << '../lib'
require 'diggit'
require 'diggit/system'

Diggit::System.init

def load_fixture(file)
  File.read(File.join(File.dirname(__FILE__), 'fixtures', file))
end

def mock_request_for(url, headers = {})
  ActionDispatch::Request.new(Rack::MockRequest.env_for(url, headers))
end
