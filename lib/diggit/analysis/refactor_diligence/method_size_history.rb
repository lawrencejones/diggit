require 'active_support/core_ext/module'
require_relative './commit_scanner'

module Diggit
  module Analysis
    module RefactorDiligence
      class MethodSizeHistory
        def initialize(repo)
          @repo = repo
          @scanner = CommitScanner.new(repo)
        end

        attr_reader :scanner
        delegate :scan, to: :scanner

        # Uses commit scanner to generate method statistics, then returns back a map
        # of method name to method size.
        #
        #   {'method_a' => 2}
        #
        def scan(commit, files:)
          scanner.scan(commit, files: files).
            transform_values { |stats| stats.fetch(:lines) }
        end

        # Generates method size history across commits for all methods located inside
        # files that are present in `restrict_to`.
        #
        # Output is of the form...
        #
        #   {'method_a' => [3, 2]}
        #
        def history(commits, restrict_to:)
          history_by_commit = history_by_commit(commits, restrict_to: restrict_to)
          initial_history = history_by_commit.first.map { |k, v| [k, [v]] }
          tracked_methods = initial_history.keys

          history_by_commit.
            each_with_object(Hamster::Hash[initial_history]) do |commit, method_sizes|
              tracked_methods.each do |method|
                last_size = method_sizes[method].last
                method_sizes[method] << commit[method] if last_size > commit[method]
                tracked_methods.delete(method) if last_size < commit[method]
              end
            end
        end

        # Produces a timeline of method sizes for each of the given commits, in commit
        # order.
        #
        # Example for two commits, where `method_a` was originally 2 lines...
        #
        #   [{'method_a' => 3}, {'method_a' => 2}]
        #
        # Only methods that were found in the original commit will be tracked.
        def history_by_commit(commits, restrict_to:)
          commits.map { |commit| scan(commit, files: restrict_to) }.
            each_with_object([]) do |method_sizes, history|
              previous_sizes = history.last || Hamster::Hash.new(method_sizes)
              tracked_methods = previous_sizes.keys
              history << previous_sizes.merge(method_sizes.slice(*tracked_methods))
            end
        end
      end
    end
  end
end
