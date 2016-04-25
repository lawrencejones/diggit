require 'active_support/core_ext/array'

module Diggit
  module Github
    class Diff
      #                      @@ -47,6 +47,7 @@ GEM
      CHUNK_HEADER_REGEX = /^@@ -(\d+),(\d+) \+(\d+),(\d+) @@/
      GITHUB_DIFF_FORMAT = 'application/vnd.github.v3.diff'.freeze

      class FileNotFound < StandardError; end

      def self.from_pull_request(repo, pull, client)
        pr = client.pull_request(repo, pull)
        base, head = pr[:base][:sha], pr[:head][:sha]

        unified_diff = client.compare(repo, base, head, accept: GITHUB_DIFF_FORMAT)
        new(unified_diff, base: base, head: head)
      end

      # See https://en.wikipedia.org/wiki/Diff_utility#Unified_format for information on
      # the diff text format.
      #
      # Yielded from github when using the application/vnd.github.v3.diff media type.
      def initialize(unified_diff, base:, head:)
        @unified_diff = unified_diff
        @base = base
        @head = head
      end

      attr_reader :head, :base

      # Computes the diff index for the given line number in the given file, where the
      # index is the line number of the appearance of that line in the head of the unified
      # diff.
      #
      # This can then be used to comment on the latest version of line_number in file on a
      # github pull request.
      def index_for(file, line_number)
        diff_for_file(file).fetch(:diff_chunks).
          reduce(0) do |index, position:, size:, diff:|
            # Unless we are processing the target chunk
            unless line_number.between?(position, position + size)
              next index + 1 + diff.lines.count
            end

            position -= 1 # rebase position on first line of chunk
            index_in_chunk = diff.lines.find_index do |line|
              position += 1 unless line.first == '-'
              position == line_number
            end

            return index + 1 + index_in_chunk
          end

        nil # if this line number is not in diff
      end

      private

      def diff_for_file(file)
        diff = file_diffs.find { |file_diff| file_diff[:new] == file }
        fail FileNotFound, "File #{file} not present in diff" if diff.nil?

        diff
      end

      def file_diffs
        @file_diffs ||= @unified_diff.split(/^(?=diff)/).map do |chunk|
          preamble, diff_content = chunk.split(/^(?=@@)/, 2)
          original_header, new_header = preamble.lines.last(2)

          { original: original_header.match(%r{--- a?/(.+)$})[1],
            new: new_header.match(%r{\+\+\+ b/(.+)$})[1],
            diff_chunks: parse_diff_chunks(diff_content) }
        end
      end

      def parse_diff_chunks(diff_chunk_text)
        diff_chunk_text.split(/^(?=@@)/).map do |chunk_text|
          stat_header, *diff_lines = chunk_text.lines
          position, size = stat_header.match(CHUNK_HEADER_REGEX).to_a.last(2).map(&:to_i)

          { position: position, size: size,
            diff: diff_lines.join }
        end
      end
    end
  end
end
