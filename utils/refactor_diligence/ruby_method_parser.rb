require 'active_support/core_ext/hash'
require 'active_support/core_ext/object'
require 'parser/ruby23'

module RefactorDiligence
  # Extracts methods and their length from ruby code
  class RubyMethodParser
    def initialize(contents)
      @ast = Parser::Ruby23.parse(contents)
    rescue Parser::SyntaxError
      # If we end up here, we should be safe to call process_methods and return an empty
      # hash. Silently failing is an ideal situation.
      nil
    end

    def methods
      @methods ||= process_methods
    end

    private

    def process_methods(node = @ast)
      case node.try(:type)
      when :def    then on_def(node)
      when :class  then on_class(node)
      when :module then on_module(node)
      when :begin  then on_begin(node)
      else
        {}
      end
    end

    def on_def(node)
      Hash[node.children.first.to_s, node_lines(node)]
    end

    def on_class(node)
      class_const, _, class_begin = node.children
      process_methods(class_begin).transform_keys do |ident|
        "#{class_const.children[1]}::#{ident}"
      end
    end

    def on_module(node)
      module_const, module_begin = node.children
      process_methods(module_begin).transform_keys do |ident|
        "#{module_const.children[1]}::#{ident}"
      end
    end

    def on_begin(node)
      node.children.map { |child| process_methods(child) }.inject(:merge)
    end

    def node_lines(node)
      1 + node.location.last_line - node.location.first_line
    end
  end
end
