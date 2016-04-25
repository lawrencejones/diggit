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

    %i(debug error fatal info log warn).each do |method|
      define_method(method) do |label = nil, &block|
        Diggit.logger.send(method, label || self.class.to_s, &block)
      end
    end
  end
end
