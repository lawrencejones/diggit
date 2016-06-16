require_relative '../../services/git_helpers'
require_relative '../../logger'
require_relative '../../models/project'
require_relative 'file_suggester'
require_relative 'changeset_generator'
require_relative 'min_support_finder'

module Diggit
  module Analysis
    module ChangePatterns
      class Report
        NAME = 'ChangePatterns'.freeze
        MIN_CONFIDENCE = 0.75 # required confidence that files are coupled
        MAX_CHANGESET_SIZE = 25 # exclude changesets of > items
        MAX_CHANGESETS = 10_000 # use this number of changesets in analysis

        include Services::GitHelpers
        include InstanceLogger

        def initialize(repo, args, config)
          @repo = repo
          @base = args.fetch(:base)
          @head = args.fetch(:head)
          @gh_path = args.fetch(:gh_path)

          @min_confidence = config.fetch(:min_confidence, MIN_CONFIDENCE)
          @ignore = config.fetch(:ignore, {})

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
            next if ignored?(file, antecedent)

            { report: self.class::NAME,
              index: file,
              location: nil, # aggregate comments for this reporter
              message: "Expected `#{file}` to change, as it was modified in "\
                       "#{(100 * confidence).to_i}% of past changes involving "\
                       "#{antecedent.map { |changed| "`#{changed}`" }.join(' ')}",
              meta: {
                missing_file: file,
                confidence: confidence,
                antecedent: antecedent.to_a,
              },
            }
          end.compact
        end

        def likely_missing_files
          FileSuggester.
            new(changesets, files_modified(base: base, head: head),
                max_items: MAX_CHANGESET_SIZE,
                min_support: min_support).
            suggest(@min_confidence)
        end

        def ignored?(file, antecedent)
          ignored_antecedent = Hamster::SortedSet.new(@ignore.fetch(file, []))
          antecedent.intersection(ignored_antecedent).any?
        end

        def min_support
          @min_support ||= MinSupportFinder.
            find(project, changesets, ls_files(head))
        end

        def changesets
          @changesets ||= ChangesetGenerator.
            # Use the master branch to avoid including commits that may not be merged
            new(repo,
                gh_path: gh_path,
                head: repo.branches['origin/master'].try(:target).try(:oid) || base).
            changesets.
            first(MAX_CHANGESETS).
            map { |cs| cs & files_in_head }
        end

        def files_in_head
          @files_in_head ||= ls_files(head)
        end
      end
    end
  end
end
