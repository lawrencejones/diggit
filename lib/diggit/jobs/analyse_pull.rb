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
        @cloner = Services::ProjectCloner.new(project)

        @logger_prefix = "[#{project.gh_path}/#{pull}]"
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

        if PullAnalysis.exists?(project: project, pull: pull, head: head, base: base)
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
            pipeline = Analysis::Pipeline.new(repo, head: head, base: base)
            info { 'Running pipeline...' }
            pipeline.aggregate_comments
          end
        end
      end

      def time_pipeline
        started_at = Time.now
        yield.tap { @pipeline_duration = Time.now - started_at }
      end

      def create_pull_analysis(pull, comments)
        info { 'Creating PullAnalysis record...' }
        PullAnalysis.create!(project: project,
                             pull: pull,
                             head: head, base: base,
                             comments: comments,
                             duration: pipeline_duration)
      end
    end
  end
end
