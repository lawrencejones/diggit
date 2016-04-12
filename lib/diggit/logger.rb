require 'logger'

module Diggit
  def self.logger
    @logger ||= Logger.new(STDOUT).tap { |logger| logger.level = Logger::INFO }
  end

  module InstanceLogger
    def logger
      Diggit.logger
    end
  end
end
