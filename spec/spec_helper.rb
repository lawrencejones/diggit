ENV['RACK_ENV'] = 'test'

require 'bundler/setup'
Bundler.setup(:default, :test)

require 'rspec'
require 'timecop'
require 'pry'
require 'coach'
require 'active_support/core_ext'
require 'database_cleaner'

Coach.require_matchers!

RSpec::Matchers.define :respond_with_json do |json_body|
  match do |middleware|
    begin
      @response_body = JSON.parse(middleware.call[2].join)
      expect(@response_body).to match(json_body)
    rescue RSpec::Expectations::ExpectationNotMetError => bad_match
      @diff = bad_match.message.match(/Diff:.*$/m)[0]
      false
    end
  end

  failure_message do |actual|
    "expected that json response body would match "\
    "#{JSON.pretty_generate(json_body)}\n#{@diff}"
  end
end

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand(config.seed)

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end

$LOAD_PATH << '../lib'
require 'diggit'
require 'diggit/system'

Diggit::System.init

def load_fixture(file)
  File.read(File.join(File.dirname(__FILE__), 'fixtures', file))
end

def load_json_fixture(file)
  JSON.parse(load_fixture(file))
end

def mock_request_for(url, headers = {})
  headers['router.params'] = headers.delete(:params) unless headers[:params].nil?
  ActionDispatch::Request.new(Rack::MockRequest.env_for(url, headers))
end
