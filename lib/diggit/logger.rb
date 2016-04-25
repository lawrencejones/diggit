require 'logger'

module Diggit
  def self.logger
    return @logger unless @logger.nil?

    File.mkdir('log') unless Dir.exist?('log')
    @logger = Logger.new('log/diggit.log', 'daily')
    @logger.level = Logger::INFO
    @logger
  end

  module InstanceLogger
    def logger
      Diggit.logger
    end
  end
end
