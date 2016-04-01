require 'coach'
require 'rack'

module Diggit
  module Middleware
    # Acts as a static server, backed by the Rack::Static middleware, with a fallback path
    # to serve from if the original request can't be fulfilled.
    #
    # Filters any requests that are on the `api` subdomain onto the next rack middleware.
    class FrontEnd < Coach::Middleware
      def call
        return cascade if request_host.starts_with?('api.')

        response = rack_static.call(request.env)
        rack_static.call(fallback_env) if response.first == 404
      end

      private

      def rack_static
        config.fetch(:rack_static)
      end

      def fallback_env
        request.env.merge('PATH_INFO' => config.fetch(:fallback_path))
      end

      def cascade
        [404, {
          'Content-Type' => 'text/plain',
          'X-Cascade' => 'pass',
        }, ["No route at #{request.path}"]]
      end

      def request_host
        request.headers.fetch('HTTP_HOST', '')
      end
    end
  end
end
