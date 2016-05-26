require 'active_support/core_ext/module'

require_relative 'method_parser'
require_relative '../../services/git_helpers'

module Diggit
  module Analysis
    module RefactorDiligence
      class MethodSizeHistory
        include Services::GitHelpers

        MAX_FILE_CHANGES = 25

        def initialize(repo, head:, files:)
          @repo = repo
          @head = head
          @files = files
        end

        attr_reader :repo, :head, :files

        # Computes the history of all methods in all files.
        def history
          @history ||= files.map { |file| history_for_file(file) }.inject(:merge)
        end

        private

        # Generates method size history for the given file.
        #
        #   { 'method_a' => [[3, 'second-sha'], [2, 'first-sha']] }
        #
        # rubocop:disable Metrics/AbcSize
        def history_for_file(file)
          commits = rev_list(commit: head, path: file).first(MAX_FILE_CHANGES)
          file_history = commits.map { |commit| [scan(file, commit), commit] }
          initial_sizes, initial_commit = file_history.first

          tracked_methods = Set.new(file_history.first.first.keys)
          initial_history = initial_sizes.map do |method, size|
            [method, [[size, initial_commit]]]
          end

          file_history.
            each_with_object(Hamster::Hash[initial_history]) do |(sizes, commit), history|
              tracked_methods.each do |method|
                last_size = history[method].last.first
                current_size = sizes[method] || last_size + 1 # mark to remove

                history[method] << [current_size, commit] if last_size > current_size
                history[method].last[1] = commit          if last_size == current_size
                tracked_methods.delete(method)            if last_size < current_size
              end
            end
        end
        # rubocop:enable Metrics/AbcSize

        # Parses method size from the given file at the given commit.
        #
        #   { 'method' => 4, ... }
        #
        def scan(file, commit)
          MethodParser.parse(cat_file(commit: commit, path: file), file: file).methods.
            transform_values { |method_info| method_info.fetch(:lines) }
        end
      end
    end
  end
end
