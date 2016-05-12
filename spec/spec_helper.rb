ENV['RACK_ENV'] = 'test'

require 'bundler/setup'
Bundler.setup(:default, :test)

if ENV['CIRCLE_ARTIFACTS']
  require 'simplecov'

  output = File.join(ENV['CIRCLE_ARTIFACTS'], 'coverage')
  SimpleCov.coverage_dir(output)
  SimpleCov.start
end

require 'rspec'
require 'rspec/its'
require 'que'
require 'timecop'
require 'pry'
require 'coach'
require 'active_support/core_ext'
require 'database_cleaner'
require 'factory_girl'
require 'shoulda-matchers'

Coach.require_matchers!

shared_examples 'passes JSON schema' do |valid_fixture|
  require 'diggit/middleware/json_schema_validation'

  subject(:instance) do
    schema_dep = described_class.middleware_dependencies.find do |dep|
      dep.middleware == Diggit::Middleware::JsonSchemaValidation
    end
    schema_dep.middleware.new(context, null_middleware, schema_dep.config)
  end

  let(:json_fixture) { load_json_fixture(valid_fixture) }
  let(:context) do
    { request: instance_double(ActionDispatch::Request,
                               env: { 'router.params' => json_fixture }) }
  end

  it { is_expected.to call_next_middleware }
end

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

  failure_message do |_actual|
    'expected that json response body would match '\
    "#{JSON.pretty_generate(json_body)}\n#{@diff}"
  end
end

require_relative 'diggit/analysis/temporary_analysis_repo'

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand(config.seed)

  config.filter_run_excluding integration: true unless ENV['INTEG']

  config.include(Shoulda::Matchers::ActiveModel)
  config.include(Shoulda::Matchers::ActiveRecord)

  config.before(:all) { FactoryGirl.reload }

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.after(:each) do
    ::Que.clear!
    TemporaryAnalysisRepo.clean!
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning { example.run }
  end
end

$LOAD_PATH << '../lib'
require 'diggit/system'

Diggit::System.init
Diggit.logger.level = Logger::WARN

def load_fixture(file)
  File.read(File.join(File.dirname(__FILE__), 'fixtures', file))
end

def load_json_fixture(file)
  JSON.parse(load_fixture(file))
end

def load_yaml_fixture(file)
  YAML.parse(load_fixture(file))
end

def mock_request_for(url, headers = {})
  headers['router.params'] = headers.delete(:params) unless headers[:params].nil?
  ActionDispatch::Request.new(Rack::MockRequest.env_for(url, headers))
end
