require 'hamster/hash'
require_relative './method_size_history'
require_relative './commit_scanner'

module Diggit
  module Analysis
    module RefactorDiligence
      class Report
        TIMES_INCREASED_THRESHOLD = 2

        def initialize(repo, conf)
          @repo = repo
          @files_changed = conf.fetch(:files_changed, [])
          @base = conf.fetch(:base)
          @head = conf.fetch(:head)
          @method_locations = CommitScanner.new(repo).
            scan(commits_of_interest.first, files: ruby_files_changed).
            transform_values { |stats| stats.fetch(:loc) }
        end

        def comments
          @comments ||= generate_comments
        end

        private

        attr_reader :repo, :files_changed, :method_locations

        def generate_comments
          methods_over_threshold.to_h.map do |method, history|
            { report: 'RefactorDiligence',
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
            history(commits_of_interest.map(&:sha), restrict_to: ruby_files_changed).
            select { |_, history| history.size > TIMES_INCREASED_THRESHOLD }.
            select { |_, history| commits_in_diff.include?(history.first[1]) }
        end

        # Generate a list of commits that contain changes to the originally modified
        # files.
        def commits_of_interest
          @commits_of_interest ||= ruby_files_changed.
            map { |ruby_file| repo.log.path(ruby_file).to_a }.
            flatten.
            uniq(&:sha).
            sort_by { |commit| -commit.date.to_i }
        end

        # Commit shas that make up the diff
        def commits_in_diff
          @commits_in_diff ||= repo.log.between(@base, @head).map(&:sha)
        end

        def ruby_files_changed
          @ruby_files_changed ||= files_changed.
            select { |file| File.extname(file) == '.rb' }
        end
      end
    end
  end
end
