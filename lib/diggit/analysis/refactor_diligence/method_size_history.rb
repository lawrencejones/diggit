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
        #   { 'method_a' => [[3, 'second-sha'], [2, 'first-sha']] }
        #
        def history(commits, restrict_to:)
          sizes_by_commit = history_by_commit(commits, restrict_to: restrict_to)
          commit_sizes, initial_sha = sizes_by_commit.first

          # Generate history seed, map of method name to lists of tuples of [size, sha]
          initial_history = commit_sizes.map { |k, size| [k, [[size, initial_sha]]] }
          tracked_methods = Set[*initial_history.keys]

          sizes_by_commit.
            each_with_object(Hamster::Hash[initial_history]) do |(sizes, sha), history|
              tracked_methods.each do |method|
                last_size = history[method].last.first
                current_size = sizes[method] || last_size + 1 # mark to remove

                history[method] << [current_size, sha] if last_size > current_size
                history[method].last[1] = sha          if last_size == current_size
                tracked_methods.delete(method)         if last_size < current_size
              end
            end
        end

        # Produces a timeline of method sizes for each of the given commits, in commit
        # order, with the associated commit sha.
        #
        # Example for two commits, where `method_a` was originally 2 lines...
        #
        #   [
        #     [{'method_a' => 3, 'method_b' => 4}, 'second-sha'],
        #     [{'method_a' => 2}, 'first-sha'],
        #   ]
        #
        # Only methods that were found in the original commit will be tracked, and once
        # a method cannot be found it will cease to be tracked.
        def history_by_commit(commits, restrict_to:)
          commits.map { |commit| scan(commit, files: restrict_to) }.
            each_with_object([]) do |method_sizes, history|
              previous_sizes = history.last || Hamster::Hash.new(method_sizes)
              tracked_methods = previous_sizes.keys.intersection(method_sizes.keys)
              history << previous_sizes.merge(method_sizes).slice(*tracked_methods)
            end.zip(commits)
        end
      end
    end
  end
end
