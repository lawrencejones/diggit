module GitWalker
  module Metrics
    def self.whitespace_complexity(filepath, _repo)
      contents = File.read(filepath)
      return 0 unless contents.valid_encoding?

      WhitespaceComplexity.new(contents).complexity
    end

    class WhitespaceComplexity
      def initialize(contents)
        @contents = contents
      end

      def complexity
        0
      end

      def indent
        @indent ||= indent_frequency.max_by { |_indent, count| count }.first
      end

      private

      attr_reader :contents

      def indent_frequency
        contents.lines.
          map { |line| line[/^( +|\t+)/] }.reject(&:nil?).
          each_with_object(count_hash) { |indent, counts| counts[indent] += 1 }
      end

      def count_hash
        {}.tap { |h| h.default = 0 }
      end
    end
  end
end
