require 'rugged'

module Diggit
  module Analysis
    module ChangePatterns
      class ChangesetGenerator
        def initialize(repo, head: nil)
          @repo = repo
          @head = head || repo.last_commit.oid
        end

        def changesets
          @changesets = generate_changesets
        end

        private

        attr_reader :repo, :head

        # Walks the repository backwards from @head, generating lists of files that have
        # changed together. Will skip merge commits (those that have >1 parent).
        def generate_changesets
          walker = Rugged::Walker.new(repo)
          walker.sorting(Rugged::SORT_DATE)
          walker.push(head)
          walker.map do |commit|
            next if commit.parents.size > 1
            commit.diff(commit.parents.first).deltas.map do |delta|
              delta.new_file[:path]
            end
          end.compact
        end
      end
    end
  end
end
