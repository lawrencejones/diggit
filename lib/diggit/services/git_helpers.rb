require 'shellwords'
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
      def rev_list(commit, path = nil)
        args = ['rev-list', commit.try(:oid) || commit]
        args.push('--', path) unless path.nil?

        command(*args).split.map do |commit_sha|
          repo.lookup(commit_sha)
        end
      end

      private

      attr_reader :repo

      def command(*args)
        opts = []
        opts << "--git-dir=#{repo.path}"
        opts << "--work-tree=#{repo.workdir}" unless repo.bare?

        io = IO.popen([GIT_BINARY, *opts, *args])
        fail('git command failed!') unless $CHILD_STATUS.success?

        io.read
      end
    end
  end
end
