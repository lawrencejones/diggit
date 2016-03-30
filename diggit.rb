require 'sinatra'
require 'sinatra/activerecord'
require 'que'
require 'json'
require 'prius'

if ENV['RACK_ENV'] == 'test'
  require 'dotenv'
  Dotenv.load(File.join(settings.root, 'dummy-env'))
end

# Environment variables
Prius.load(:diggit_env, env_var: 'RACK_ENV')
Prius.load(:diggit_domain)
Prius.load(:diggit_github_token)

module Diggit
  class App < Sinatra::Base
    set :public_folder, Proc.new { File.join(root, 'dist') }
    set :environment, Prius.get(:diggit_env)
    enable :logging

    # Database configuration
    register Sinatra::ActiveRecordExtension
    Que.connection = ActiveRecord
    Que.mode = settings.environment == 'production' ? :async : :sync

    before '/webhooks/github' do
      begin
        request.body.rewind
        params.merge!(json_body: JSON.parse(request.body.read))
      rescue JSON::ParserError
        halt 400, 'Could not parse JSON'
      end
    end

    get '/ping' do
      'pong!'
    end
  end
end
