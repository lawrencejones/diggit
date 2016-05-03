require 'thread'

module Diggit
  module Services
    module Environment
      def self.semaphore
        @semaphore ||= Mutex.new
      end

      def self.with_temporary_env(env, &block)
        semaphore.synchronize do
          old_env = ENV.to_h.slice(*env.keys)
          env.each { |k, v| ENV[k] = v }

          begin
            result = block.call
          ensure
            old_env.each { |k, v| ENV[k] = v }
          end

          result
        end
      end
    end
  end
end
