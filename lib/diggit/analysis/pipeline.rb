require 'hamster/hash'

require_relative './refactor_diligence/report'
require_relative '../logger'

module Diggit
  module Analysis
    class Pipeline
      REPORTERS = [RefactorDiligence::Report].freeze
      include InstanceLogger

      def initialize(repo, head:, base:)
        @repo = repo
        @head = head
        @base = base
      end

      def aggregate_comments
        REPORTERS.map do |report|
          logger.info('Analysis::Pipeline') { "Generating #{report} for #{repo_label}..." }
          with_temp_repo { report.new(repo, files_changed: files_changed).comments }
        end.flatten
      end

      private

      attr_reader :repo, :head, :base

      def repo_label
        File.basename(repo.dir.path)
      end

      def files_changed
        @files_changed ||= repo.diff(base, head).stats[:files].keys
      end

      def with_temp_repo
        repo.reset_hard(head)
        repo.with_temp_index do
          yield(repo).tap { repo.reset_hard(head) }
        end
      end
    end
  end
end
