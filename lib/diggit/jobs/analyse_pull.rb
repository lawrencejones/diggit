require 'que'
require 'tempfile'

require_relative 'push_analysis_comments'
require_relative '../logger'
require_relative '../models/project'
require_relative '../models/pull_analysis'
require_relative '../analysis/pipeline'
require_relative '../services/project_cloner'

module Diggit
  module Jobs
    class AnalysePull < Que::Job
      include InstanceLogger

      def run(gh_path, pull, head, base)
        @pull = pull
        @head = head
        @base = base
        @project = Project.find_by!(gh_path: gh_path)

        @logger_prefix = "[#{project.gh_path}/#{pull}]"
        @cloner = Services::ProjectCloner.new(project, logger_prefix: @logger_prefix)

        return destroy unless validate

        ActiveRecord::Base.transaction do
          create_analysis
          destroy
        end
      end

      private

      attr_reader :project, :cloner, :pull, :head, :base
      attr_accessor :pipeline_duration

      def validate
        unless project && project.watch
          info { 'Not watched, doing nothing' }
          return false
        end

        analysis = PullAnalysis.
          find_by(project: project, pull: pull, head: head, base: base)

        if analysis.present? && (Analysis::Pipeline.reporters - analysis.reporters).empty?
          info { 'Pull already analysed, doing nothing' }
          return false
        end

        true
      end

      def create_analysis
        comments = generate_comments(head, base)
        pull_analysis = create_pull_analysis(pull, comments)
        PushAnalysisComments.enqueue(pull_analysis.id) unless project.silent
      rescue Analysis::Pipeline::BadGitHistory
        info { 'Pull references commits that no longer exist, skipping analysis' }
      end

      def generate_comments(head, base)
        cloner.clone do |repo|
          time_pipeline do
            pipeline = Analysis::Pipeline.
              new(repo, head: head, base: base, gh_path: project.gh_path)
            info { 'Running pipeline...' }
            pipeline.aggregate_comments
          end
        end
      end

      def time_pipeline
        started_at = Time.zone.now
        yield.tap { @pipeline_duration = Time.zone.now - started_at }
      end

      def create_pull_analysis(pull, comments)
        info { 'Creating PullAnalysis record...' }
        ActiveRecord::Base.transaction do
          analysis = PullAnalysis.
            find_or_create_by!(project: project,
                               pull: pull,
                               head: head, base: base)
          analysis.update!(comments: comments,
                           duration: pipeline_duration,
                           reporters: Analysis::Pipeline.reporters)
          analysis
        end
      end
    end
  end
end
