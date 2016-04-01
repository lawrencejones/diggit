require 'json'

module Routes
  class Github
    class Ping < Coach::Middleware
      def call
        [200, {}, ["pong!\n"]]
      end
    end
  end
end
