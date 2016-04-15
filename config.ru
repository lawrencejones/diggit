require 'bundler/setup'
Bundler.setup(:default, ENV['RACK_ENV'])

require_relative 'lib/diggit/system'
config = Diggit::System.init
run Diggit::Application.new(config).rack_app
