require 'hanami/router'
require 'coach'
require 'jwt'
require 'unirest'

require_relative '../services/jwt'

module Diggit
  module Routes
    module Auth
      GITHUB_AUTHORIZE = 'https://github.com/login/oauth/authorize'.freeze
      GITHUB_GET_ACCESS_TOKEN = 'https://github.com/login/oauth/access_token'.freeze
      STATE_EXPIRATION = 10 # minutes
      TOKEN_EXPIRATION = 2 * 60 # minutes

      class Redirect < Coach::Middleware
        def call
          [302, { 'Location' => "#{GITHUB_AUTHORIZE}?#{request_query}" }, []]
        end

        private

        def request_query
          config.slice(:client_id, :scope).
            merge(state: create_state).
            map { |param_key, value| "#{param_key}=#{URI.encode(value)}" }.
            join('&')
        end

        def create_state
          Services::Jwt.encode('github', Time.now.advance(minutes: STATE_EXPIRATION).to_i)
        end
      end

      class CreateAccessToken < Coach::Middleware
        def call
          return error('invalid_state') unless valid_state?

          gh_token, oauth_error = access_token_from_github
          return error('bad_oauth_exchange') if gh_token.nil? || oauth_error.present?

          access_token = Services::Jwt.
            encode({ gh_token: gh_token },
                   Time.now.advance(minutes: TOKEN_EXPIRATION).to_i)

          [200, {}, [{ access_token: { token: access_token } }.to_json]]
        end

        private

        def error(message)
          [401, {}, [{ error: message }.to_json]]
        end

        def access_token_from_github
          query_string = URI.encode_www_form(
            client_id: config.fetch(:client_id),
            client_secret: config.fetch(:client_secret),
            code: params['code'],
            state: params['state'])

          response = Unirest.
            post("#{GITHUB_GET_ACCESS_TOKEN}?#{query_string}",
                 headers: { 'Accept' => 'application/json' })

          [response.body['access_token'], response.body['error']]
        end

        def valid_state?
          Services::Jwt.decode(params['state'])['data'] == 'github'
        rescue JWT::ExpiredSignature, JWT::VerificationError, JWT::DecodeError
          return false
        end
      end
    end
  end
end
