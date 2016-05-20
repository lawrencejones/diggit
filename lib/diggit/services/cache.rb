require 'redis'
require 'oj'
require 'prius'

module Diggit
  module Services
    # Redis backed key value cache, with value serialization
    module Cache
      def self.prefix
        "diggit-#{Prius.get(:diggit_env)}"
      end

      def self.conn
        @conn ||= Redis.new
      end

      def self.store(key, value)
        conn.set("#{prefix}:#{key}", Oj.dump(value))
      end

      def self.get(key)
        value = conn.get("#{prefix}:#{key}")
        Oj.load(value) unless value.nil?
      end

      def self.delete(key)
        conn.del("#{prefix}:#{key}")
      end
    end
  end
end
