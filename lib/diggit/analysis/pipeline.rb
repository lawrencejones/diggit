require 'hamster/hash'

require_relative 'refactor_diligence/report'
require_relative 'complexity/report'
require_relative '../logger'

module Diggit
  module Analysis
    class Pipeline
      REPORTERS = [RefactorDiligence::Report, Complexity::Report].freeze
      MAX_FILES_CHANGED = 25

      class BadGitHistory < StandardError; end
      include InstanceLogger

      def initialize(repo, head:, base:)
        @repo = repo
        @head = head
        @base = base

        @logger_prefix ||= "[#{File.basename(repo.workdir)}]"
        verify_refs!
      end

      def aggregate_comments
        return [] unless validate_diff_size

        REPORTERS.map do |report|
          info { "#{report}..." }
          repo.reset(head, :hard)
          report.new(repo, base: base, head: head).comments
        end.flatten
      end

      private

      attr_reader :repo, :head, :base

      def validate_diff_size
        return true if no_files_changed < MAX_FILES_CHANGED

        info { "#{no_files_changed} files changed, too large, skipping" }
        false
      end

      def verify_refs!
        fail BadGitHistory, "Missing base commit #{base}" unless repo.exists?(base)
        fail BadGitHistory, "Missing head commit #{head}" unless repo.exists?(head)
      end

      def no_files_changed
        repo.diff(base, head).deltas.count
      end
    end
  end
end
