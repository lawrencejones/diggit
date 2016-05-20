require 'rugged'

require_relative '../../logger'
require_relative '../../services/cache'
require_relative '../../services/git_helpers'

module Diggit
  module Analysis
    module ChangePatterns
      # Generate a list of changesets from the given repo. This operation can take some
      # time, so cache the result using diggit's cache.
      class ChangesetGenerator
        include InstanceLogger
        include Services::GitHelpers

        def initialize(repo, gh_path:, head: nil)
          @repo = repo
          @gh_path = gh_path
          @head = head || repo.last_commit.oid
          @current_files = ls_files(@head)

          @logger_prefix = "[#{gh_path}]"
          @changeset_cache = Services::Cache.get("#{gh_path}/changesets") || {}
        end

        # Generates list of changesets
        #
        #     [
        #       ['file.rb', 'another_file.rb'],
        #       ['file.rb'],
        #       ..,
        #     ]
        #
        def changesets
          @changesets = begin
            fetch_and_update_cache.values.map { |changeset| current_files & changeset }
          end
        end

        private

        attr_reader :repo, :head, :gh_path, :current_files, :changeset_cache

        # Load cache, walk repo, update cache
        def fetch_and_update_cache
          changeset_cache.merge(generate_commit_changesets).tap do |commit_changesets|
            Services::Cache.store("#{gh_path}/changesets", commit_changesets)
          end
        end

        # Walks the repository backwards from @head, generating lists of files that have
        # changed together. Will skip merge commits (those that have >1 parent).
        def generate_commit_changesets
          walker.each_with_object({}) do |commit, commit_changesets|
            next if commit.parents.size > 1
            commit_changesets[commit.oid] = commit.
              diff(commit.parents.first).deltas.
              map { |delta| delta.new_file[:path] }
          end.reject { |oid, changeset| changeset.blank? }
        end

        # Creates a new commit walker that will ignore commits already present in the
        # cache.
        def walker
          Rugged::Walker.new(repo).tap do |walker|
            walker.sorting(Rugged::SORT_DATE)
            walker.push(head)
            walker.hide(changeset_cache.keys)
          end
        end
      end
    end
  end
end
