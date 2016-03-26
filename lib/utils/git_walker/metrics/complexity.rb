require 'active_support/core_ext/hash'
require 'descriptive-statistics'

module GitWalker
  module Metrics
    def self.complexity(filepath, _repo)
      contents = File.read(filepath)
      return 0 unless contents.valid_encoding?

      # Scale the standard deviation so that outliers are more apparent
      ((3 * WhitespaceAnalysis.new(contents).std)**2).floor
    end

    class WhitespaceAnalysis
      def initialize(contents)
        @contents = contents
      end

      # Correlates well with other tests of complexity, such as Cyclomatic Complexity.
      # Will evaluate as 0 if the contents is not indented.
      def std
        @std ||= stats(logical_indents).standard_deviation || 0.0
      end

      # Inferred unit of indentation, by default ' '
      def nominal_indent
        @nominal_indent ||= stats(whitespace_indents.reject(&:empty?)).mode || ' '
      end

      private

      attr_reader :contents

      def stats(collection)
        DescriptiveStatistics::Stats.new(collection)
      end

      # The logical level of indentation for each indented line, computed as the number of
      # nominal indent tokens that are found in the whitespace.
      def logical_indents
        @logical_indents ||= whitespace_indents.
          map { |whitespace| whitespace.scan(nominal_indent).count }
      end

      # All leading whitespace from each line
      def whitespace_indents
        @whitespace_indents ||= contents.lines.
          map { |line| line.match(/^( *|\t*)\S|/)[1] }.
          reject(&:nil?)
      end
    end
  end
end
