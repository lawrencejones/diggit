require 'logger'

module Diggit
  def self.logger
    return @logger unless @logger.nil?

    Dir.mkdir('log') unless Dir.exist?('log')
    @logger = Logger.new('log/diggit.log', 'daily')
    @logger.level = Logger::INFO
    @logger
  end

  module InstanceLogger
    def logger
      Diggit.logger
    end

    def self.included(base)
      base.extend(InstanceLogger)
    end

    def log_payload(message)
      { thread: Thread.current.object_id, pid: Process.pid,
        class: self.class.to_s, message: message }
    end

    %i(debug error fatal info log warn).each do |method|
      define_method(method) do |label = nil, &block|
        Diggit.logger.send(method) do
          payload = block.call
          payload = log_payload(payload) if payload.class == String
          payload[:message] = [logger_prefix, payload[:message]].compact.join(' ')
          payload.to_json
        end
      end
    end

    attr_accessor :logger_prefix
  end
end
