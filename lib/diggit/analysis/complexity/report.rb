require 'action_view/helpers'
require_relative 'whitespace_analysis'

module Diggit
  module Analysis
    module Complexity
      class Report
        IGNORED_EXTENSIONS = %w(.json .xml .yaml).freeze
        CHANGE_WINDOW = 3
        CHANGE_THRESHOLD = 50.0

        extend ActionView::Helpers::DateHelper

        def self.compute_complexity(content)
          WhitespaceAnalysis.new(content).std
        end

        def self.humanize_duration(head, base)
          distance_of_time_in_words(base.date, head.date, include_seconds: false)
        end

        def initialize(repo, conf)
          @repo = repo
          @base = conf.fetch(:base)
          @head = conf.fetch(:head)
        end

        def comments
          @comments ||= generate_comments
        end

        private

        attr_reader :base, :head, :repo

        def generate_comments
          files_above_threshold.to_h.map do |file, (complexity_increase, head, base)|
            { report: 'Complexity',
              location: "#{file}:1",
              message: "`#{file}` has increased in complexity by "\
                       "#{complexity_increase.to_i}% over the last "\
                       "#{self.class.humanize_duration(head, base)}",
              meta: {
                file: file,
                complexity_increase: complexity_increase,
                head: head.sha, base: base.sha
              },
            }
          end
        end

        # Selects those files that exceed the CHANGE_THRESHOLD from the changed files
        # complexity history.
        def files_above_threshold
          file_complexity_change.select do |_file, (complexity_increase)|
            complexity_increase >= CHANGE_THRESHOLD
          end
        end

        # Computes how much the complexity of the file has increased, in percentage,
        # over the last CHANGE_WINDOW changes.
        #
        #   { 'file.rb' => [56.8, latest_commitish, lowest_committish] }
        #
        def file_complexity_change
          files_with_complexity_increase.map do |file, complexity_history|
            head, head_complexity = complexity_history.first
            base, base_complexity = complexity_history.min_by(&:last)

            change = (head_complexity - base_complexity) / base_complexity
            pct_change = (100 * change).round(2)

            [file, [pct_change, head, base]]
          end.reject { |k, _v| k.nil? }
        end

        # Filter file histories for those that have increased in complexity in this last
        # change.
        def files_with_complexity_increase
          file_complexity_history.select do |_file, complexity_history|
            _, head_complexity = complexity_history.first
            _, previous_complexity = complexity_history.first(2).last

            head_complexity > previous_complexity
          end
        end

        # Compute the history of a files complexity, retaining the associated commitish
        #
        #   { 'file.rb' => [[commitish, 56.8], ...] }
        #
        def file_complexity_history
          @file_complexity_history ||= file_changes.map do |file, changes|
            [file, changes.first(CHANGE_WINDOW).map do |commit|
              [commit, self.class.compute_complexity(repo.show(commit, file))]
            end]
          end
        end

        # Generate a map of file to commit objects where that file has been changed,
        # taking only the last commit of each day.
        #
        #   { 'file.rb' => [commitish, ...] }
        #
        def file_changes
          tracked_files.reduce(Hamster::Hash.new) do |changes, file|
            last_commits_of_the_day = repo.log.path(file).
              group_by { |commit| commit.date.to_date }.
              map { |(_, commits)| commits.max_by(&:date) }.
              sort_by { |commit| -commit.date.to_i }
            changes.merge(file => last_commits_of_the_day)
          end.reject { |_file, history| history.empty? }
        end

        # All files that should be scanned for complexity growth.
        def tracked_files
          @tracked_files ||= repo.
            diff(base, head).stats[:files].keys.
            reject { |file| IGNORED_EXTENSIONS.include?(File.extname(file)) }
        end
      end
    end
  end
end
