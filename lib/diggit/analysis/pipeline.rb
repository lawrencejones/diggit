require 'logger'
require 'hamster/hash'

module Diggit
  module Analyse
    logger = Logger.new(STDOUT)
    logger.level = Logger::INFO

    class Pipeline
      TOOLS = []

      def initialize(repo, head:, base:)
        @repo = repo
        @head = head
        @base = base
      end

      def run
        TOOLS.reduce(Hamster::Hash.new) do |report, tool|
          logger.info('Analyse::Pipeline') { "Running #{tool} on #{repo_label}..." }
          analysis = tool.new # TODO
          report.merge(label(tool) => analysis)
        end
      end

      private

      attr_reader :repo

      def repo_label
        File.basename(repo.dir.path)
      end

      def label(cls)
        cls.name.split('::').last.underscore.to_sym
      end
    end
  end
end
