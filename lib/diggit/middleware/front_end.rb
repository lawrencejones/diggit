require 'coach'
require 'rack'

module Diggit
  module Middleware
    # Acts as a static server, backed by the Rack::Static middleware, with a fallback path
    # to serve from if the original request can't be fulfilled.
    class FrontEnd < Coach::Middleware
      def call
        response = rack_static.call(request.env)
        response.first == 404 ? rack_static.call(fallback_env) : response
      end

      private

      def rack_static
        config.fetch(:rack_static)
      end

      def fallback_env
        request.env.merge('PATH_INFO' => config.fetch(:fallback_path))
      end
    end
  end
end
