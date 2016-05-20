require_relative '../../services/git_helpers'
require_relative 'file_suggester'
require_relative 'changeset_generator'
require_relative 'fp_growth'

module Diggit
  module Analysis
    module ChangePatterns
      class Report
        MIN_SUPPORT = 5 # required coupled changes to be seen as associated
        MIN_CONFIDENCE = 0.75 # required confidence that files are coupled
        MAX_CHANGESET_SIZE = 25 # exclude changesets of > items

        include Services::GitHelpers

        def initialize(repo, conf)
          @repo = repo
          @base = conf.fetch(:base)
          @head = conf.fetch(:head)
          @changeset_generator = ChangesetGenerator.
            new(repo, head: head, gh_path: conf.fetch(:gh_path))
        end

        def comments
          @comments ||= generate_comments
        end

        private

        attr_reader :base, :head, :changeset_generator
        delegate :changesets, to: :changeset_generator

        def generate_comments
          likely_missing_files.map do |file, confidence:, antecedent:|
            { report: 'ChangePatterns',
              index: file,
              location: "#{file}:1",
              message: "`#{file}` was modified in #{(100 * confidence).to_i}% of "\
                       "past changes involving these files...\n"\
                       "```\n#{antecedent.join("\n")}\n```",
              meta: {
                missing_file: file,
                confidence: confidence,
                antecedent: antecedent.to_a,
              },
            }
          end
        end

        def likely_missing_files
          FileSuggester.
            new(frequent_itemsets,
                min_confidence: MIN_CONFIDENCE).
            suggest(files_modified(base: base, head: head))
        end

        def frequent_itemsets
          FpGrowth.
            new(changesets,
                min_support: MIN_SUPPORT,
                max_items: MAX_CHANGESET_SIZE).
            frequent_itemsets
        end
      end
    end
  end
end
