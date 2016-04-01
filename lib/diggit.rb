require 'hanami/router'
require 'coach'
require 'uri'
require 'rack'

require_relative 'diggit/routes/github'
require_relative 'diggit/middleware/front_end'

module Diggit
  class Application
    PUBLIC = File.expand_path('../../public', __FILE__)

    def initialize(config)
      @host = URI.parse(config.fetch(:host))
      @github_token = config.fetch(:github_token)
      @rack_app = build_rack_app
    end

    attr_reader :rack_app, :host

    private

    def build_rack_app
      opt = { host: @host.host,
              scheme: @host.scheme,
              force_ssl: @host.scheme == 'https' }

      Hanami::Router.new(opt).tap do |router|
        router.mount build_front_end, at: '/'
        router.get '/ping', to: Coach::Handler.new(Routes::Github::Ping)
      end
    end

    def build_front_end
      Coach::Handler.new(
        Middleware::FrontEnd,
        rack_static: Rack::Static.new(nil, root: PUBLIC, urls: ['']),
        fallback_path: '/index.html')
    end
  end
end
