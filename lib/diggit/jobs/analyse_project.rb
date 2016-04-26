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

      # rubocop:disable Metrics/AbcSize
      def run(project_id, pull, head, base)
        @project = Project.find(project_id)
        @cloner = Github::Cloner.new(project.ssh_private_key)
        @comment_generator = Github::CommentGenerator.
          new(project.gh_path, pull, Github.client)

        unless project && project.watch
          info { "#{project.gh_path} is not watched, doing nothing" }
          return destroy
        end

        if PullAnalysis.exists?(project: project, pull: pull)
          info { "Pull #{pull} for #{project.gh_path} already analysed, doing nothing" }
          return destroy
        end

        ActiveRecord::Base.transaction do
          comments = generate_comments(head, base)
          create_pull_analysis(pull, comments)
          comment_to_github(comments)

          destroy
        end
      end
      # rubocop:enable Metrics/AbcSize

      private

      attr_reader :project, :cloner, :comment_generator
      delegate :add_comment, to: :comment_generator

      def generate_comments(head, base)
        info { "Cloning #{project.gh_path}..." }
        cloner.clone(project.gh_path) do |repo|
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
