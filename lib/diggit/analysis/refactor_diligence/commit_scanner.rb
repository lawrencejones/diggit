require 'logger'
require_relative './ruby_method_parser'

module Diggit
  module Analysis
    module RefactorDiligence
      # Scans the repo at specific commits for the results of parsing ruby methods.
      class CommitScanner
        def initialize(repo)
          @repo = repo
        end

        def scan(ref, files: nil)
          checkout(ref)
          scan_methods(files || all_ruby_files)
        end

        private

        attr_reader :repo, :logger

        def checkout(ref)
          repo.reset_hard(ref)
          repo.object(ref)
        end

        def scan_methods(ruby_files)
          ruby_files.
            map { |ruby_file| [ruby_file, read_if_exists(ruby_file)] }.to_h.compact.
            map { |ruby_file, ruby| RubyMethodParser.new(ruby, file: ruby_file).methods }.
            inject(:merge) || {}
        end

        def read_if_exists(file)
          Dir.chdir(repo.dir.path) { File.read(file) if File.exist?(file) }
        end
      end
    end
  end
end
