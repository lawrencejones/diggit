require 'hamster/hash'
require_relative './method_size_history'
require_relative './commit_scanner'
require_relative '../../services/git_helpers'

module Diggit
  module Analysis
    module RefactorDiligence
      class Report
        TIMES_INCREASED_THRESHOLD = 2

        include Services::GitHelpers

        def initialize(repo, conf)
          @repo = repo
          @base = conf.fetch(:base)
          @head = conf.fetch(:head)
        end

        def comments
          @comments ||= parseable_files_changed.empty? ? [] : generate_comments
        end

        private

        attr_reader :repo, :base, :head, :method_locations

        def generate_comments
          methods_over_threshold.to_h.map do |method, history|
            { report: 'RefactorDiligence',
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
        def methods_over_threshold
          @methods_over_threshold ||= method_size_history.
            select { |_, history| history.size > TIMES_INCREASED_THRESHOLD }.
            select { |_, history| commits_in_diff.include?(history.first[1].oid) }
        end

        # Parses all the changed files changed in head to identify the location of each
        # method in the head commit.
        #
        #   { 'method' => 'file.rb:4', ... }
        #
        def method_locations
          @method_locations ||= parseable_files_changed.
            map { |file| [file, cat_file(commit: head, path: file)] }.
            map { |(file, contents)| MethodParser.parse(contents, file: file).methods }.
            inject(:merge).
            transform_values { |method_info| method_info.fetch(:loc) }
        end

        def method_size_history
          @method_size_history ||= MethodSizeHistory.
            new(repo, head: head, files: parseable_files_changed).
            history
        end

        def commits_in_diff
          @commits_in_diff ||= commits_between(base, head).map(&:oid)
        end

        def parseable_files_changed
          @parseable_files_changed ||= repo.
            diff(repo.merge_base(base, head), head).deltas.
            reject { |delta| delta.status == :deleted }.
            map { |delta| delta.new_file[:path] }.
            select { |file| MethodParser.supported?(file) }
        end
      end
    end
  end
end
