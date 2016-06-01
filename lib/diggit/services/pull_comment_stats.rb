require_relative '../models/pull_analysis'

module Diggit
  module Services
    # Aggregate comments by resolved status
    class PullCommentStats
      def initialize(project, pull)
        @project = project
        @pull = pull
      end

      attr_reader :project, :pull

      def comments
        @comments ||= analyses.
          flat_map(&:comments).
          uniq { |comment| index_of(comment) }.
          freeze
      end

      # All comments that have appeared in pull but are resolved by the last analysis
      def resolved
        @resolved ||= comments.
          reject do |comment|
            comment_index = index_of(comment)
            unresolved.any? { |u| index_of(u) == comment_index }
          end.freeze
      end

      # All pending comments on last analysis
      def unresolved
        @unresolved ||= analyses.last.comments
      end

      private

      def index_of(comment)
        comment.slice('report', 'index')
      end

      def indexes
        @indexes ||= comments.map { |comment| comment.slice('report', 'index') }
      end

      def analyses
        PullAnalysis.where(project: project, pull: pull).order(:created_at)
      end
    end
  end
end
