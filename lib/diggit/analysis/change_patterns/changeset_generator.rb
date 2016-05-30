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

        # Specify how many changesets to keep in storage
        MAX_CHANGESETS = 10_000

        def initialize(repo, gh_path:, head: nil)
          @repo = Rugged::Repository.new(repo.workdir)
          @gh_path = gh_path
          @head = head || repo.last_commit.oid
          @current_files = ls_files(@head)

          @logger_prefix = "[#{gh_path}]"
          @changeset_cache = Services::Cache.get("#{gh_path}/changesets") || []
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
            fetch_and_update_cache.map { |entry| current_files & entry[:changeset] }
          end
        end

        private

        attr_reader :repo, :head, :gh_path, :current_files, :changeset_cache

        # Load cache, walk repo, update cache
        def fetch_and_update_cache
          info { 'Walking repo...' }
          new_changesets = generate_commit_changesets.
            reject { |entry| entry[:changeset].blank? }
          repo.close # to free used memory
          info { "Found #{new_changesets.size} new changesets" }

          changeset_cache.concat(new_changesets).
            sort_by { |entry| -entry[:timestamp] }.
            take(MAX_CHANGESETS).
            tap do |commit_changesets|
              Services::Cache.store("#{gh_path}/changesets", commit_changesets)
            end
        end

        # Walks the repository backwards from @head, generating lists of files that have
        # changed together. Will skip merge commits (those that have >1 parent).
        #
        #     [
        #       { oid: 'commit-sha', changeset: [..], timestamp: 12345678 },
        #       ..,
        #     ]
        #
        def generate_commit_changesets
          walker.each_with_object([]) do |commit, commit_changesets|
            next unless commit.parents.size == 1
            return commit_changesets if commit_changesets.size >= MAX_CHANGESETS

            commit_changesets << {
              oid: commit.oid,
              changeset: commit_diff(commit),
              timestamp: commit.author[:time].to_i,
            }
          end
        end

        def commit_diff(commit)
          commit.diff(commit.parents.first).deltas.map { |delta| delta.new_file[:path] }
        end

        def commits_in_cache
          @commits_in_cache ||= changeset_cache.map { |entry| entry[:oid] }
        end

        # Creates a new commit walker that will ignore commits already present in the
        # cache.
        def walker
          Rugged::Walker.new(repo).tap do |walker|
            walker.sorting(Rugged::SORT_DATE)
            walker.push(head)
            walker.hide(commits_in_cache)
          end
        end
      end
    end
  end
end
