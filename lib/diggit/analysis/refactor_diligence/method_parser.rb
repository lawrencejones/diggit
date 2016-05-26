require_relative 'ruby_method_parser'
require_relative 'python_method_parser'

module Diggit
  module Analysis
    module RefactorDiligence
      class MethodParser
        PARSERS = [RubyMethodParser, PythonMethodParser].freeze

        EXTENSIONS = PARSERS.flat_map { |parser| parser::EXTENSIONS }.freeze
        PARSER_MAP = PARSERS.flat_map do |parser|
          parser::EXTENSIONS.map { |extension| [extension, parser] }
        end.to_h.freeze

        # Delegate parsing to the appropriate parser for this extension
        def self.parse(contents, file:)
          parser = PARSER_MAP.fetch(File.extname(file))
          parser.new(contents, file: file)
        end

        def self.supported?(file)
          EXTENSIONS.include?(File.extname(file))
        end
      end
    end
  end
end
