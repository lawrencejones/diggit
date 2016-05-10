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
          @comments ||= commits_of_interest.empty? ? [] : generate_comments
        end

        private

        attr_reader :repo, :base, :head, :method_locations

        def generate_comments
          methods_over_threshold.to_h.map do |method, history|
            { report: 'RefactorDiligence',
              index: method,
              location: method_locations.fetch(method),
              message: "#{method} has increased in size the last "\
                       "#{history.size} times it has been modified - "\
                       "#{history.map(&:last).join(' ')}",
              meta: {
                method_name: method,
                times_increased: history.size,
              },
            }
          end
        end

        def methods_over_threshold
          @methods_over_threshold ||= MethodSizeHistory.new(repo).
            history(commits_of_interest.map(&:oid), restrict_to: ruby_files_changed).
            select { |_, history| history.size > TIMES_INCREASED_THRESHOLD }.
            select { |_, history| commits_in_diff.include?(history.first[1]) }
        end

        # Generate a list of commits that contain changes to the originally modified
        # files.
        def commits_of_interest
          @commits_of_interest ||= ruby_files_changed.
            flat_map { |ruby_file| rev_list(head, ruby_file) }.
            uniq(&:oid).
            sort_by { |commit| -commit.author[:time].to_i }
        end

        # Identifies the location of each method in the latest commit
        def method_locations
          @method_locations ||= CommitScanner.new(repo).
            scan(commits_of_interest.first.oid, files: ruby_files_changed).
            transform_values { |stats| stats.fetch(:loc) }
        end

        # Commit shas that make up the diff
        def commits_in_diff
          @commits_in_diff ||= commits_between(base, head).map(&:oid)
        end

        def ruby_files_changed
          @ruby_files_changed ||= repo.
            diff(repo.merge_base(base, head), head).deltas.
            reject { |delta| delta.status == :deleted }.
            map { |delta| delta.new_file[:path] }.
            select { |file| File.extname(file) == '.rb' }
        end
      end
    end
  end
end
