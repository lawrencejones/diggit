require 'active_support/core_ext/object'

module Diggit
  module Services
    # Provides convinience methods for running git operations on the Rugged::Repository
    # instance stored as @repo on the current class.
    #
    # Some methods call out to the git binary when libgit2 fails to provide required
    # functionality.
    module GitHelpers
      GIT_BINARY = 'git'.freeze

      # Runs the rev-list command, returning an array of commit shas that are ancestors of
      # the given commit, filtered by path if one is supplied.
      def rev_list(commit:, path: nil)
        args = ['rev-list', '--remove-empty', commit.try(:oid) || commit]
        args.push('--', path) unless path.nil?

        command(*args).split.map do |commit_sha|
          repo.lookup(commit_sha)
        end
      end

      # Generates the string content of the blob located at `path` in commit `commit`.
      # Returns nil if file does not exist in this commit.
      def cat_file(commit:, path:)
        tree = commit.try(:tree) || repo.lookup(commit).tree

        blob_entry = path.split('/').reduce(tree) do |treeish, ref|
          entry = treeish[ref]
          break if entry.nil?
          repo.lookup(entry[:oid])
        end

        return blob_entry.read_raw.data unless blob_entry.nil?
        nil
      end

      # Finds those files that have changed between base and head, excluding those that
      # have been deleted.
      def files_modified(base:, head:)
        repo.diff(repo.merge_base(base, head), head).deltas.
          reject { |delta| delta.status == :deleted }.
          map    { |delta| delta.new_file[:path] }
      end

      # Finds the commits between the common ancestor of base and head, and head.
      def commits_between(base, head)
        common_ancestor = repo.merge_base(base, head)

        Rugged::Walker.new(repo).tap do |walker|
          walker.sorting(Rugged::SORT_DATE)
          walker.push(head)
          walker.hide(common_ancestor)
        end.to_a
      end

      private

      attr_reader :repo

      def command(*args)
        opts = []
        opts << "--git-dir=#{repo.path}"
        opts << "--work-tree=#{repo.workdir}" unless repo.bare?

        io = IO.popen([GIT_BINARY, *opts, *args])
        _, status = Process.wait2(io.pid)

        fail("git command failed!\n\n#{output}") unless status == 0

        io.read
      end
    end
  end
end
