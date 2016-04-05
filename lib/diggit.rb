require 'hanami/router'
require 'coach'
require 'uri'
require 'rack'

require_relative 'diggit/routes/auth'
require_relative 'diggit/routes/projects'
require_relative 'diggit/middleware/front_end'

module Diggit
  class Application
    PUBLIC = File.expand_path('../../public', __FILE__)
    Handler = Coach::Handler

    def initialize(config)
      @host = URI.parse(config.fetch(:host))
      @config = config
      @rack_app = build_rack_app
    end

    attr_reader :rack_app, :host, :config

    private

    def uri_to(path)
      uri = host.clone
      uri.path = path
      uri.to_s
    end

    def build_rack_app
      opt = { host: @host.host,
              scheme: @host.scheme,
              force_ssl: @host.scheme == 'https' }

      Hanami::Router.new(opt).tap do |router|
        router.mount build_api_rack, at: '/api'
        router.mount build_front_end, at: '/'
      end
    end

    def build_api_rack
      Hanami::Router.new(parsers: [:json]).tap do |router|
        router.mount build_auth, at: '/auth'
        router.mount build_projects, at: '/projects'

        router.get '/ping', to: ->(_env) { [200, {}, ["pong!\n"]] }
      end
    end

    def build_front_end
      Handler.new(
        Middleware::FrontEnd,
        rack_static: Rack::Static.new(nil, root: PUBLIC, urls: ['']),
        fallback_path: '/index.html')
    end

    def build_auth
      Hanami::Router.new.tap do |router|
        router.get '/redirect', to: Coach::Handler.
          new(Routes::Auth::Redirect,
              client_id: config.fetch(:github_client_id),
              scope: 'write:repo_hook,repo')
        router.post '/access_token', to: Coach::Handler.
          new(Routes::Auth::CreateAccessToken,
              client_id: config.fetch(:github_client_id),
              client_secret: config.fetch(:github_client_secret))
      end
    end

    def build_projects
      Hanami::Router.new.tap do |router|
        router.get '/', to: Coach::Handler.new(Routes::Projects::Index)
        router.put '/:owner/:repo', to: Coach::Handler.
          new(Routes::Projects::Update,
              webhook_endpoint: config.fetch(:webhook_endpoint))
      end
    end
  end
end
