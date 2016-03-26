require 'logger'
require_relative './ruby_method_parser'

module RefactorDiligence
  # Provides the ability to scan a specific commit for method sizes. Modifies the work
  # tree while doing so.
  class CommitScanner
    def initialize(repo)
      @repo = repo
      @logger = Logger.new(STDERR).tap do |log|
        log.progname = 'CommitScanner'
        log.level = Logger.const_get(ENV.fetch('LOG_LEVEL', 'WARN').upcase)
      end
    end

    def scan(ref, files: nil)
      logger.debug("SCAN #{ref}")
      checkout(ref)
      scan_method_sizes(files || all_ruby_files)
    end

    private

    attr_reader :repo, :logger

    def checkout(ref)
      repo.reset_hard(ref)
      repo.object(ref)
    end

    def scan_method_sizes(ruby_files)
      ruby_files.
        map    { |ruby_file| read_if_exists(ruby_file) }.compact.
        map    { |ruby| RubyMethodParser.new(ruby).methods }.
        inject(:merge) || {}
    end

    def read_if_exists(file)
      Dir.chdir(repo.dir.path) { File.read(file) if File.exist?(file) }
    end

    def all_ruby_files
      Dir.chdir(repo.dir.path) { Dir['**/*.rb'] }
    end
  end
end
