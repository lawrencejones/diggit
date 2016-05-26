require 'que'
require 'prius'
require 'active_support/core_ext/module'

require_relative 'cron_job'
require_relative '../services/mailer'
require_relative '../logger'

module Diggit
  module Jobs
    class DailyAnalysisSummary < CronJob
      include InstanceLogger
      include Services::Mailer

      TEMPLATE_PATH = File.expand_path('../daily_analysis_summary.html.erb', __FILE__)

      deliver_to 'lawrjone@gmail.com'
      subject '[diggit] Daily Analysis Summary'
      html_body File.read(TEMPLATE_PATH)

      SCHEDULE_AT = ['20:00'].freeze

      def run
        info { 'Generating summary...' }
        send!
        info { 'Sent!' }
      end

      private

      def link_for_pull(project, pull)
        "#{link_for_project(project)}/pull/#{pull}"
      end

      def link_for_project(project)
        "https://github.com/#{project.gh_path}"
      end

      def last_day
        @last_day ||= start_at.advance(days: -1)...start_at
      end

      # Generate summary of analyses for this project, sorting by the pull id.
      #
      #   [ { pull: 5, no_of_analyses: 2, no_of_comments: 3 }, ... ]
      #
      def new_analyses_for(project)
        PullAnalysis.
          where(project: project, created_at: last_day).
          group_by(&:pull).map do |pull, analyses|
            unique_comments = analyses.
              flat_map(&:comments).
              map { |comment| comment.slice('report', 'index') }

            { pull: pull, no_of_analyses: analyses.count,
              no_of_comments: unique_comments.size }
          end.sort_by { |analysis| analysis[:pull] }
      end

      def projects_with_new_analyses
        @projects_with_new_analyses ||= Project.
          where(id: new_analyses.uniq.pluck(:project_id))
      end

      def duration_stats
        return @duration_stats unless @duration_stats.nil?

        analyses = new_analyses.order('-duration')
        ten_pct = [1, new_analyses.count / 10].max
        @duration_stats = {
          average: analyses.average(:duration).to_i,
          max: analyses.maximum(:duration).to_i,
          tp_90: analyses.limit(ten_pct).reduce(0) do |avg, analysis|
            avg + analysis.duration / ten_pct
          end.to_i,
        }
      end

      # Summary count of each comment, split by reporter.
      #
      #   { 'RefactorDiligence' => 5,
      #     'Complexity' => 3, ... }
      #
      def new_comment_count
        @new_comment_count ||= new_analyses.
          flat_map(&:comments).
          map { |comment| comment.slice('report', 'index') }.
          group_by { |comment| comment['report'] }.
          transform_values(&:count)
      end

      # All new analyses, in ActiveRecord form
      def new_analyses
        @new_analyses ||= PullAnalysis.where(created_at: last_day)
      end
    end
  end
end
