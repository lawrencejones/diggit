ENV['RACK_ENV'] ||= 'development'

require 'hamster/hash'
require 'que'
require 'active_record'
require 'yaml'
require 'rack'
require 'coach'

require_relative './logger'
require_relative '../../config/prius'

module Diggit
  class System
    DUMMY_ENV = File.expand_path('../../../dummy-env', __FILE__)
    DATABASE_YAML = File.expand_path('../../../config/database.yml', __FILE__)

    def self.rack_app
      config = init
      Diggit::Application.new(config).rack_app
    end

    def self.init
      @config ||= begin
        configure_rollbar!
        configure_active_record!
        configure_que!

        Coach::Middleware.class_eval do
          define_method(:params) { request.env['router.params'] }
        end

        require_relative '../diggit'
        require_relative 'services/jwt'
        require_relative 'services/secure'

        Diggit::Services::Jwt.secret = Prius.get(:diggit_secret)
        Diggit::Services::Secure.secret = Prius.get(:diggit_secret)

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

    def self.configure_rollbar!
      return unless ENV.key?('DIGGIT_ROLLBAR_TOKEN')

      require 'rollbar'
      Rollbar.configure do |config|
        config.access_token = ENV['DIGGIT_ROLLBAR_TOKEN']
      end
    end

    def self.configure_active_record!
      unless defined?(Rake) || %w(test production).include?(Prius.get(:diggit_env))
        ActiveRecord::Base.logger = Diggit.logger
      end

      database_config = ENV['DATABASE_URL']
      database_config ||= YAML.load_file(DATABASE_YAML).fetch(Prius.get(:diggit_env))
      ActiveRecord::Base.establish_connection(database_config)
    end

    def self.configure_que!
      Que.connection = ActiveRecord
      Que.mode = Prius.get(:diggit_env) == 'test' ? :sync : :async
      Que.logger = Diggit.logger if ENV.key?('LOG_QUE')
    end
  end
end
