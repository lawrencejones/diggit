ENV['RACK_ENV'] ||= 'development'

require 'hamster/hash'
require 'logger'
require 'que'
require 'active_record'
require 'yaml'
require 'rack'
require 'coach'

require_relative '../diggit'
require_relative 'services/jwt'

module Diggit
  class System
    DUMMY_ENV = File.expand_path('../../../dummy-env', __FILE__)
    DATABASE_YAML = File.expand_path('../../../config/database.yml', __FILE__)

    def self.init
      @config ||= begin
        load_config!
        configure_active_record!
        configure_que!

        Coach::Middleware.class_eval do
          define_method(:params) { request.env['router.params'] }
        end

        Diggit::Services::Jwt.secret = Prius.get(:diggit_secret)

        # Load all database models
        require_relative 'models/project'

        Hamster::Hash.new(
          env: Prius.get(:diggit_env),
          host: Prius.get(:diggit_host),
          secret: Prius.get(:diggit_secret),
          github_client_id: Prius.get(:diggit_github_client_id),
          github_client_secret: Prius.get(:diggit_github_client_secret),
          github_token: Prius.get(:diggit_github_token),
          webhook_endpoint: Prius.get(:diggit_webhook_endpoint)
        )
      end
    end

    def self.start
      app = Diggit::Application.new(@config)
      Rack::Server.start(app: app.rack_app, Port: ENV['PORT'] || app.host.port)
    end

    def self.load_config!
      unless ENV['RACK_ENV'] == 'production'
        require 'dotenv'
        Dotenv.load(DUMMY_ENV)
      end

      require_relative '../../config/prius'
    end

    def self.configure_active_record!
      unless defined?(Rake) || %w(test production).include?(Prius.get(:diggit_env))
        ActiveRecord::Base.logger = Logger.new(STDOUT)
      end

      database_config = ENV['DATABASE_URL']
      database_config ||= YAML.load_file(DATABASE_YAML).fetch(Prius.get(:diggit_env))
      ActiveRecord::Base.establish_connection(database_config)
    end

    def self.configure_que!
      Que.connection = ActiveRecord
    end
  end
end
