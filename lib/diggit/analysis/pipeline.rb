require 'hamster/hash'

require_relative 'refactor_diligence/report'
require_relative 'complexity/report'
require_relative '../logger'

module Diggit
  module Analysis
    class Pipeline
      REPORTERS = [RefactorDiligence::Report, Complexity::Report].freeze
      class BadGitHistory < StandardError; end
      include InstanceLogger

      def initialize(repo, head:, base:)
        @repo = repo
        @head = head
        @base = base

        verify_head!
      end

      def aggregate_comments
        REPORTERS.map do |report|
          info { "[#{repo_label}] #{report}..." }
          with_temp_repo do
            report.new(repo, base: base, head: head).comments
          end
        end.flatten
      end

      private

      attr_reader :repo, :head, :base

      def verify_head!
        repo.show(head)
      rescue Git::GitExecuteError
        raise BadGitHistory, "Missing head commit #{head}"
      end

      def repo_label
        File.basename(repo.dir.path)
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
