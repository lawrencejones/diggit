require 'hamster/hash'

require_relative '../logger'
require_relative '../services/git_helpers'
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

      DIGGIT_CONFIG_FILE = '.diggit.yml'.freeze
      MAX_FILES_CHANGED = 25

      # [ 'RefactorDiligence', 'Complexity', ... ]
      def self.reporters
        REPORTERS.map { |report| report::NAME }
      end

      class BadGitHistory < StandardError; end
      include InstanceLogger
      include Services::GitHelpers

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
          report.
            new(repo,
                { base: base, head: head, gh_path: gh_path },
                reporter_config.fetch(report::NAME, {}).symbolize_keys).
            comments
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
        @no_files_changed = files_modified(base: base, head: head).count
      end

      def reporter_config
        if @gh_path == 'gocardless/payments-service'
          # Special case gc
          return { 'ChangePatterns' => { ignore: { 'Gemfile' => ['Gemfile.lock'] } } }
        end

        @reporter_config ||= YAML.
          load(cat_file(commit: head, path: DIGGIT_CONFIG_FILE) || '{}')
      end
    end
  end
end
