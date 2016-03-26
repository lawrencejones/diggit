require 'sinatra'
require 'json'
require 'prius'

# Environment variables
Prius.load(:diggit_domain)
Prius.load(:diggit_github_token)

module Diggit
  class App < Sinatra::Base
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
