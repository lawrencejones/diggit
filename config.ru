require 'bundler/setup'
Bundler.setup(:default, ENV['RACK_ENV'])

require_relative 'lib/diggit/system'
run(Diggit::System.rack_app)
