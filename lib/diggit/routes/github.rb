require 'hanami/router'
require 'coach'
require 'jwt'

module Diggit
  module Routes
    module Github
      GITHUB_AUTHORIZE = 'https://github.com/login/oauth/authorize'.freeze
      JWT_ALGORITHM = 'HS256'.freeze
      STATE_EXPIRATION = 10 * 60 # 10m

      def self.state_create(secret)
        JWT.encode({
                     data: 'github',
                     exp: Time.now.to_i + STATE_EXPIRATION,
                   }, secret, JWT_ALGORITHM)
      end

      def self.state_verify(state_token, secret)
        decoded, = JWT.decode(state_token, secret, true, algorithm: JWT_ALGORITHM)
        decoded['data'] == 'github'
      rescue JWT::ExpiredSignature, JWT::VerificationError, JWT::DecodeError
        return false
      end

      class Redirect < Coach::Middleware
        def call
          [302, { 'Location' => "#{GITHUB_AUTHORIZE}?#{request_query}" }, []]
        end

        private

        def request_query
          config.slice(:client_id, :scope, :redirect_uri).
            merge(state: Github.state_create(config.fetch(:secret))).
            map { |param_key, value| "#{param_key}=#{URI.encode(value)}" }.
            join('&')
        end
      end
    end
  end
end
