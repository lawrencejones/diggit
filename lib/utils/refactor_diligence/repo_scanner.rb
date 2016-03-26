require 'hamster'
require 'logger'
require_relative './commit_scanner'

module RefactorDiligence
  # Loads a git repo and instruments the creation of method size history, by scanning
  # backwards from an initial git reference to the oldest trackable parent.
  #
  # NB - Due to the scanning process, methods that are removed in the git history will not
  # display as such in the generated method size history. They will instead register as
  # the last known method size value.
  class RepoScanner
    def initialize(repo)
      @repo = repo
      @scanner = CommitScanner.new(repo)
      @logger = Logger.new(STDERR).tap do |log|
        log.progname = 'RepoScanner'
        log.level = Logger.const_get(ENV.fetch('LOG_LEVEL', 'WARN').upcase)
      end
    end

    def scan_back_from(initial_ref)
      initial_commit = repo.object(initial_ref)

      all_commits_from(initial_ref).
        tap { |commits| logger.debug("NO OF COMMITS #{commits.size}") }.
        each_with_object([Hamster::Hash[scan(initial_commit.sha)]]) do |commit, history|
          modified_files = modified_ruby_files(commit.diff_parent)
          method_sizes = scan(commit.sha, files: modified_files)

          history.push(history.last.merge(method_sizes))
        end
    end

    private

    attr_reader :repo, :scanner, :logger

    delegate :scan, to: :scanner

    def all_commits_from(ref)
      Enumerator.new do |y|
        commit = repo.object(ref)
        y << commit while (commit = commit.parent)
      end.to_a
    end

    def modified_ruby_files(diff)
      diff.stats[:files].keys.
        select { |file| File.extname(file) == '.rb' }
    end
  end
end
