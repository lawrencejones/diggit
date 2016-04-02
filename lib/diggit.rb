require 'hanami/router'
require 'coach'
require 'uri'
require 'rack'

require_relative 'diggit/routes/github'
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
      Hanami::Router.new.tap do |router|
        router.mount build_github, at: '/github'

        router.get '/ping', to: ->(_env) { [200, {}, ["pong!\n"]] }
      end
    end

    def build_front_end
      Handler.new(
        Middleware::FrontEnd,
        rack_static: Rack::Static.new(nil, root: PUBLIC, urls: ['']),
        fallback_path: '/index.html')
    end

    def build_github
      Hanami::Router.new.tap do |router|
        router.get '/redirect', to: Coach::Handler.
          new(Routes::Github::Redirect,
              secret: config.fetch(:secret),
              client_id: config.fetch(:github_client_id),
              scope: 'write:repo_hook,repo',
              redirect_uri: uri_to('/api/github/oauth_callback'))
      end
    end
  end
end
