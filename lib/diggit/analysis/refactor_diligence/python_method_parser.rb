module Diggit
  module Analysis
    module RefactorDiligence
      class PythonMethodParser
        EXTENSIONS = %w(.py).freeze

        CLASS_DEFINITION = /^(?<ws>\s*)(?<token>class)\s+(?<ident>[^\(:]+)/
        FUNCTION_DEFINITION = /^(?<ws>\s*)(?<token>def)\s+(?<ident>[^\(]+)/

        def initialize(contents, file: '')
          @contents = contents
          @file = file
          @prefix = []
          @stack = []
        end

        # Generates method location, with file prefix, and line count of each method.
        #
        #   { 'Class::method' => { loc: 'class.py:4', lines: 4 } }
        #
        def methods
          @methods ||= generate_methods.transform_values do |stats|
            { loc: "#{file}:#{stats[:loc]}", lines: stats[:lines] }
          end
        end

        private

        attr_reader :contents, :file

        def generate_methods
          lines.each_with_index.each_with_object({}) do |(line, index), methods|
            next if line.blank?
            increment_line_count(line, index)

            match = line.match(CLASS_DEFINITION) || line.match(FUNCTION_DEFINITION)
            next unless match

            pop_stack_for_line(line)
            push_declaration(match, index)

            methods[@prefix.join('::')] = @stack.last if match[:token] == 'def'
          end
        end

        # Update all currently tracked blocks with new line count
        def increment_line_count(line, index)
          @stack.each do |block|
            if line.starts_with?(block[:block_indent])
              block[:lines] = 2 + index - block[:loc]
            end
          end
        end

        # Pop blocks from the stack until we have the parent block for this line
        def pop_stack_for_line(line)
          until @stack.empty? || line.starts_with?(@stack.last[:block_indent])
            @prefix.pop
            @stack.pop
          end
        end

        # Create a new block on the stack
        def push_declaration(match, index)
          @prefix << match[:ident]
          @stack << { loc: index + 1, block_indent: block_indent(index), lines: 1 }
        end

        # Find the indentation for the block declared at `line_index`
        def block_indent(line_index)
          declaration_indent = lines[line_index].match(/^\s*/)[0]

          next_block_line = lines.from(line_index + 1).find do |line|
            !line.blank? && line.starts_with?(declaration_indent)
          end

          (next_block_line || '').match(/^\s*/)[0]
        end

        def lines
          @lines ||= contents.lines.to_a
        end
      end
    end
  end
end
