require 'que'
require 'git'
require 'tempfile'

require_relative 'push_analysis_comments'
require_relative '../logger'
require_relative '../models/project'
require_relative '../models/pull_analysis'
require_relative '../analysis/pipeline'
require_relative '../github/cloner'

module Diggit
  module Jobs
    class AnalysePull < Que::Job
      include InstanceLogger

      def run(gh_path, pull, head, base)
        @pull = pull
        @head = head
        @base = base
        @project = Project.find_by!(gh_path: gh_path)
        @cloner = Github::Cloner.new(project.gh_path)

        return destroy unless validate

        ActiveRecord::Base.transaction do
          create_analysis
          destroy
        end
      end

      private

      attr_reader :project, :cloner, :pull, :head, :base

      def validate
        unless project && project.watch
          info { "#{project.gh_path} is not watched, doing nothing" }
          return false
        end

        if PullAnalysis.exists?(project: project, pull: pull, head: head, base: base)
          info { "Pull #{pull} for #{project.gh_path} already analysed, doing nothing" }
          return false
        end

        true
      end

      def create_analysis
        comments = generate_comments(head, base)
        pull_analysis = create_pull_analysis(pull, comments)
        PushAnalysisComments.enqueue(pull_analysis.id) unless project.silent
      rescue Analysis::Pipeline::BadGitHistory
        info { "Pull #{pull} references commits that no longer exist, skipping analysis" }
      end

      def clone(&block)
        info { "Cloning #{project.gh_path}..." }
        return cloner.clone(&block) unless project.ssh_private_key
        cloner.clone_with_key(project.ssh_private_key, &block)
      end

      def generate_comments(head, base)
        clone do |repo|
          pipeline = Analysis::Pipeline.new(repo, head: head, base: base)
          info { "Running pipeline on #{project.gh_path}..." }
          pipeline.aggregate_comments
        end
      end

      def create_pull_analysis(pull, comments)
        info { 'Creating PullAnalysis record...' }
        PullAnalysis.create!(project: project,
                             pull: pull,
                             head: head, base: base,
                             comments: comments)
      end
    end
  end
end
