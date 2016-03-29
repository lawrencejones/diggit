require 'sinatra'
require 'sinatra/activerecord'
require 'que'
require 'json'
require 'prius'

# Environment variables
Prius.load(:diggit_env, env_var: 'RUBY_ENV')
Prius.load(:diggit_domain)
Prius.load(:diggit_github_token)

module Diggit
  class App < Sinatra::Base
    register Sinatra::ActiveRecordExtension
    Que.connection = ActiveRecord
    Que.mode = Prius.get(:diggit_env) == 'production' ? :async : :sync
    enable :logging

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
