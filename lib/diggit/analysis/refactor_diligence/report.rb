require 'hamster/hash'
require_relative './method_size_history'
require_relative './commit_scanner'
require_relative '../../services/git_helpers'

module Diggit
  module Analysis
    module RefactorDiligence
      class Report
        NAME = 'RefactorDiligence'.freeze
        TIMES_INCREASED_THRESHOLD = 3
        MIN_METHOD_SIZE = 6

        include Services::GitHelpers

        def initialize(repo, args, config)
          @repo = repo
          @base = args.fetch(:base)
          @head = args.fetch(:head)

          @min_method_size = config.fetch(:min_method_size, MIN_METHOD_SIZE)
          @times_increased_threshold = config.
            fetch(:times_increased_threshold, TIMES_INCREASED_THRESHOLD)
          @ignore = config.fetch(:ignore, [])
        end

        def comments
          @comments ||= tracked_paths.empty? ? [] : generate_comments
        end

        private

        attr_reader :repo, :base, :head, :method_locations

        def generate_comments
          methods_over_threshold.to_h.map do |method, history|
            { report: self.class::NAME,
              index: method,
              location: method_locations.fetch(method),
              message: "`#{method}` has increased in size the last "\
                       "#{history.size} times it has been modified - "\
                       "#{history.map(&:last).map(&:oid).join(' ')}",
              meta: {
                method_name: method,
                times_increased: history.size,
              },
            }
          end
        end

        # Filters for methods that have increased in size beyond the threshold, and saw
        # their last size increase happen in this diff.
        #
        # Only count commits where method size is above MIN_METHOD_SIZE
        def methods_over_threshold
          @methods_over_threshold ||= method_size_history.
            select { |_, history| commits_in_diff.include?(history.first[1].oid) }.
            each   { |_, history| history.select! { |(size)| size > @min_method_size } }.
            select { |_, history| history.size > @times_increased_threshold }
        end

        # Parses all the changed files changed in head to identify the location of each
        # method in the head commit.
        #
        #   { 'method' => 'file.rb:4', ... }
        #
        def method_locations
          @method_locations ||= tracked_paths.
            map { |file| [file, cat_file(commit: head, path: file)] }.
            map { |(file, contents)| MethodParser.parse(contents, file: file).methods }.
            inject(:merge).
            transform_values { |method_info| method_info.fetch(:loc) }
        end

        def method_size_history
          MethodSizeHistory.
            new(repo, head: head, files: tracked_paths).
            history
        end

        def commits_in_diff
          @commits_in_diff ||= commits_between(base, head).map(&:oid)
        end

        def tracked_paths
          @tracked_paths ||= files_modified(base: base, head: head).
            select { |file| MethodParser.supported?(file) }.
            reject { |file| @ignore.include?(file) }
        end
      end
    end
  end
end
