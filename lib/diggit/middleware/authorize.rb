require 'coach'
require_relative '../services/jwt'

module Diggit
  module Middleware
    class Authorize < Coach::Middleware
      class NotAuthorized < StandardError; end

      provides :gh_token

      def call
        return not_authorized('missing_authorization_header') unless header.present?
        return not_authorized('malformed_authorization_header') unless jwt_cipher.present?

        token = Diggit::Services::Jwt.decode(jwt_cipher)['data']
        provide(gh_token: token['gh_token'])

        next_middleware.call

      rescue JWT::ExpiredSignature
        not_authorized('expired_authorization_header')
      rescue JWT::VerificationError, JWT::DecodeError
        not_authorized('bad_authorization_header')
      rescue NotAuthorized => err
        not_authorized(err.message)
      end

      private

      def not_authorized(error)
        [401, {}, [{ error: error }.to_json]]
      end

      def header
        request.headers['Authorization']
      end

      def jwt_cipher
        @jwt_cipher ||= header.match(/^Bearer (\S+)$/).to_a[1]
      end
    end
  end
end
