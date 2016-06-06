require 'action_view/helpers'
require_relative '../../services/git_helpers'
require_relative 'whitespace_analysis'

module Diggit
  module Analysis
    module Complexity
      class Report
        IGNORED_EXTENSIONS = %w(.json .xml .yml .yaml).freeze
        CHANGE_WINDOW = 3
        CHANGE_THRESHOLD = 50.0

        include Services::GitHelpers
        extend ActionView::Helpers::DateHelper

        def self.compute_complexity(content)
          WhitespaceAnalysis.new(content).std
        end

        def self.humanize_duration(head, base)
          distance_of_time_in_words(base.author[:time],
                                    head.author[:time],
                                    include_seconds: false)
        end

        def initialize(repo, args, config)
          @repo = repo
          @base = args.fetch(:base)
          @head = args.fetch(:head)

          @change_window = config.fetch(:change_window, CHANGE_WINDOW)
          @change_threshold = config.fetch(:change_threshold, CHANGE_THRESHOLD)
          @ignore = config.fetch(:ignore, [])
        end

        def comments
          @comments ||= generate_comments
        end

        private

        attr_reader :base, :head, :repo

        def generate_comments
          paths_above_threshold.to_h.map do |path, (complexity_increase, head, base)|
            { report: 'Complexity',
              index: path,
              location: "#{path}:1",
              message: "`#{path}` has increased in complexity by "\
                       "#{complexity_increase.to_i}% over the last "\
                       "#{self.class.humanize_duration(head, base)}",
              meta: {
                file: path,
                complexity_increase: complexity_increase,
                head: head.oid, base: base.oid
              },
            }
          end
        end

        # Selects those paths that exceed the CHANGE_THRESHOLD from the changed paths
        # complexity history.
        def paths_above_threshold
          path_complexity_change.select do |_, (complexity_increase)|
            complexity_increase >= @change_threshold
          end
        end

        # Computes how much the complexity of the path has increased, in percentage,
        # over the last @change_window changes.
        #
        #   { 'file.rb' => [56.8, latest_commitish, lowest_committish] }
        #
        def path_complexity_change
          paths_with_complexity_increase.map do |path, complexity_history|
            head, head_complexity = complexity_history.first
            base, base_complexity = complexity_history.min_by(&:last)

            change = (head_complexity - base_complexity) / base_complexity
            change = 0.0 if change.infinite?
            pct_change = (100 * change).round(2)

            [path, [pct_change, head, base]]
          end
        end

        # Filter path histories for those that have increased in complexity in this last
        # change.
        def paths_with_complexity_increase
          path_complexity_history.select do |_, complexity_history|
            _, head_complexity = complexity_history.first
            _, previous_complexity = complexity_history.first(2).last

            head_complexity > previous_complexity
          end
        end

        # Compute the history of a paths complexity, retaining the associated commitish
        #
        #   { 'file.rb' => [[commitish, 56.8], ...] }
        #
        def path_complexity_history
          @path_complexity_history ||= path_changes.map do |path, changes|
            [path, changes.first(@change_window).map do |commit|
              file_content = cat_file(path: path, commit: commit) || ''
              [commit, self.class.compute_complexity(file_content)]
            end]
          end
        end

        # Generate a map of path to commit objects where that path has been changed,
        # taking only the last commit of each day.
        #
        #   { 'file.rb' => [commitish, ...] }
        #
        def path_changes
          tracked_paths.reduce(Hamster::Hash.new) do |changes, path|
            last_commits_of_the_day = rev_list(commit: repo.head.target, path: path).
              group_by { |commit| commit.author[:time].to_date }.
              map { |(_, commits)| commits.max_by { |c| c.author[:time] } }.
              sort_by { |commit| -commit.author[:time].to_i }
            changes.merge(path => last_commits_of_the_day)
          end.reject { |_, history| history.empty? }
        end

        def tracked_paths
          @tracked_paths ||= files_modified(base: base, head: head).
            reject { |path| IGNORED_EXTENSIONS.include?(File.extname(path)) }.
            reject { |path| @ignore.include?(path) }
        end
      end
    end
  end
end
