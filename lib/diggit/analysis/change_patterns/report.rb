require_relative '../../services/git_helpers'
require_relative '../../logger'
require_relative '../../models/project'
require_relative 'file_suggester'
require_relative 'changeset_generator'
require_relative 'fp_growth'
require_relative 'min_support_finder'

module Diggit
  module Analysis
    module ChangePatterns
      class Report
        MIN_CONFIDENCE = 0.75 # required confidence that files are coupled
        MAX_CHANGESET_SIZE = 25 # exclude changesets of > items

        include Services::GitHelpers
        include InstanceLogger

        def initialize(repo, conf)
          @repo = repo
          @base = conf.fetch(:base)
          @head = conf.fetch(:head)
          @gh_path = conf.fetch(:gh_path)
          @project = Project.find_by!(gh_path: @gh_path)

          @logger_prefix = "[#{gh_path}]"
        end

        def comments
          @comments ||= generate_comments
        end

        private

        attr_reader :base, :head, :gh_path, :project

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
                min_support: min_support,
                max_items: MAX_CHANGESET_SIZE).
            frequent_itemsets.
            tap { |itemsets| info { "Found #{itemsets.count} frequent itemsets!" } }
        end

        # Use the minimum support parameter saved to the project, else generate one
        def min_support
          if project.min_support == 0
            info { 'Finding appropriate min_support parameter...' }
            min_support = MinSupportFinder.
              new(FpGrowth, changesets, ls_files(repo.last_commit)).
              support
            info { "Updating project with min_support=#{min_support}..." }
            project.update!(min_support: min_support)
          end

          project.min_support
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
