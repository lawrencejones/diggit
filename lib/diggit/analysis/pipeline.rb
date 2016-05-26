require 'hamster/hash'

require_relative '../logger'
require_relative 'refactor_diligence/report'
require_relative 'complexity/report'
require_relative 'change_patterns/report'

module Diggit
  module Analysis
    class Pipeline
      REPORTERS = [
        RefactorDiligence::Report,
        Complexity::Report,
        ChangePatterns::Report,
      ].freeze

      MAX_FILES_CHANGED = 25

      # [ 'RefactorDiligence', 'Complexity', ... ]
      def self.reporters
        REPORTERS.map { |r| r.parent.name.demodulize }
      end

      class BadGitHistory < StandardError; end
      include InstanceLogger

      def initialize(repo, head:, base:, gh_path:)
        @repo = repo
        @head = head
        @base = base
        @gh_path = gh_path

        @logger_prefix ||= "[#{gh_path}]"
        verify_refs!
      end

      def aggregate_comments
        return [] unless validate_diff_size

        REPORTERS.map do |report|
          info { "#{report}..." }
          repo.reset(head, :hard)
          report.new(repo, base: base, head: head, gh_path: gh_path).comments
        end.flatten
      end

      private

      attr_reader :repo, :head, :base, :gh_path

      def validate_diff_size
        return true if no_files_changed < MAX_FILES_CHANGED

        info { "#{no_files_changed} files changed, too large, skipping" }
        false
      end

      def verify_refs!
        raise BadGitHistory, "Missing base commit #{base}" unless repo.exists?(base)
        raise BadGitHistory, "Missing head commit #{head}" unless repo.exists?(head)
      end

      def no_files_changed
        repo.diff(base, head).deltas.count
      end
    end
  end
end
