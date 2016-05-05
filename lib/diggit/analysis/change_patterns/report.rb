require_relative '../../services/git_helpers'

module Diggit
  module Analysis
    module ChangePatterns
      class Report
        MIN_SUPPORT = 5 # required coupled changes to be seen as associated
        MIN_CONFIDENCE = 0.5 # required confidence that files are coupled
        MAX_CHANGESET_SIZE = 25 # exclude changesets of > items

        include Services::GitHelpers

        def initialize(repo, conf)
          @repo = repo
          @base = conf.fetch(:base)
          @head = conf.fetch(:head)
        end

        def comments
          @comments ||= generate_comments
        end

        private

        attr_reader :base, :head

        def generate_comments
          likely_missing_files.map do |(file, confidence)|
            { report: 'ChangePatterns',
              index: file,
              location: "#{file}:1",
              message: "`#{file}` was expected to be modified in this change! "\
                       "[#{confidence.to_i}% confidence]",
              meta: {
                missing_file: file,
                confidence: confidence,
              }
            }
          end
        end

        def likely_missing_files
          []
        end

        # TODO - Probably move into TransactionGenerator
        def transactions
          @transactions ||= files_modified.
            map { |file| rev_list(head, path: file) }.uniq.
            map { |commit| files_modified_in(commit) }
        end
      end
    end
  end
end
