require_relative '../../services/git_helpers'
require_relative '../../logger'
require_relative 'file_suggester'
require_relative 'changeset_generator'
require_relative 'fp_growth'

module Diggit
  module Analysis
    module ChangePatterns
      class Report
        MIN_CONFIDENCE = 0.75 # required confidence that files are coupled
        MAX_CHANGESET_SIZE = 25 # exclude changesets of > items

        # Scale the required minimum support by the number of changesets we have available
        def self.min_support_for(no_of_changesets)
          case no_of_changesets
          when 0..5_000      then 5
          when 5_000..10_000 then no_of_changesets / 1_000
          else                    10
          end
        end

        include Services::GitHelpers
        include InstanceLogger

        def initialize(repo, conf)
          @repo = repo
          @base = conf.fetch(:base)
          @head = conf.fetch(:head)
          @gh_path = conf.fetch(:gh_path)

          @logger_prefix = "[#{gh_path}]"
        end

        def comments
          @comments ||= generate_comments
        end

        private

        attr_reader :base, :head, :gh_path

        def generate_comments
          likely_missing_files.map do |file, confidence:, antecedent:|
            { report: 'ChangePatterns',
              index: file,
              location: "#{file}:1",
              message: "Expected `#{file}` to change, as it was modified in "\
                       "#{(100 * confidence).to_i}% of past changes involving "\
                       "#{antecedent.map { |changed| "`#{changed}`" }.join(' ')}",
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
                min_support: self.class.min_support_for(changesets.size),
                max_items: MAX_CHANGESET_SIZE).
            frequent_itemsets.
            tap { |itemsets| info { "Found #{itemsets.count} frequent itemsets!" } }
        end

        def changesets
          @changesets ||= ChangesetGenerator.
            # Use base to avoid including commits that may not be merged into master
            new(repo, head: base, gh_path: gh_path).
            changesets
        end
      end
    end
  end
end
