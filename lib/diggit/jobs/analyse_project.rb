require 'que'
require 'git'
require 'tempfile'

require_relative '../logger'
require_relative '../models/project'
require_relative '../models/pull_analysis'
require_relative '../analysis/pipeline'
require_relative '../github/client'
require_relative '../github/comment_generator'
require_relative '../github/cloner'

module Diggit
  module Jobs
    class AnalyseProject < Que::Job
      include InstanceLogger

      def run(project_id, pull, head, base)
        @pull = pull
        @project = Project.find(project_id)
        @cloner = Github::Cloner.new(project.gh_path)
        @comment_generator = Github::CommentGenerator.
          new(project.gh_path, pull, Github.client)

        return destroy unless validate

        ActiveRecord::Base.transaction do
          run_analysis(head, base)
          destroy
        end
      end

      private

      attr_reader :project, :cloner, :comment_generator, :pull
      delegate :add_comment, to: :comment_generator

      def validate
        unless project && project.watch
          info { "#{project.gh_path} is not watched, doing nothing" }
          return false
        end

        if PullAnalysis.exists?(project: project, pull: pull)
          info { "Pull #{pull} for #{project.gh_path} already analysed, doing nothing" }
          return false
        end

        true
      end

      def run_analysis(head, base)
        comments = generate_comments(head, base)
        create_pull_analysis(pull, comments)
        comment_to_github(comments)
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
        PullAnalysis.create!(project: project, pull: pull, comments: comments)
      end

      def comment_to_github(comments)
        comments.each { |comment| add_comment(comment[:message], comment[:location]) }
        info { "Pushing #{comment_generator.pending} comments to github..." }
        comment_generator.push
      end
    end
  end
end
