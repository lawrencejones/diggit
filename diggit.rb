#!/usr/bin/env ruby
require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/subdomain'
require 'que'
require 'json'
require 'prius'

require_relative 'lib/models/project'

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
    set :environment, Prius.get(:diggit_env)
    enable :logging
    enable :static

    register Sinatra::Subdomain

    # Database configuration
    register Sinatra::ActiveRecordExtension
    Que.connection = ActiveRecord
    Que.mode = settings.environment == 'production' ? :async : :sync

    subdomain :api do
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

    get '*' do
      File.read(File.join(settings.root, 'public/index.html'))
    end
  end
end
