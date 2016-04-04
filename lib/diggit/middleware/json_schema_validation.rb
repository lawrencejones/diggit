require 'coach'
require 'json-schema'

module Diggit
  module Middleware
    class JsonSchemaValidation < Coach::Middleware
      def call
        JSON::Validator.validate!(schema, params)
        next_middleware.call
      rescue JSON::Schema::ValidationError => err
        validation_error(err)
      end

      private

      def schema
        config.fetch(:schema)
      end

      def validation_error(err)
        [400, {}, [{
          type: 'validation_error',
          message: err.message,
        }.to_json]]
      end
    end
  end
end
