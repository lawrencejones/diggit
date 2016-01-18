require 'hamster'
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
    end

    def scan_back_from(initial_ref)
      commit = repo.object(initial_ref)
      history_of_method_sizes = [Hamster::Hash.new(scan(commit.sha))]

      while (commit = commit.parent)
        modified_files = modified_ruby_files(commit.diff_parent)
        method_sizes = scan(commit.sha, files: modified_files)

        history_of_method_sizes.push(history_of_method_sizes.last.merge(method_sizes))
      end

      history_of_method_sizes
    end

    private

    attr_reader :repo, :scanner

    delegate :scan, to: :scanner

    def modified_ruby_files(diff)
      diff.stats[:files].keys.
        select { |file| File.extname(file) == '.rb' }
    end
  end
end
