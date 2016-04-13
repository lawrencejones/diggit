require 'que'
require 'git'
require 'tempfile'

require_relative '../models/project'
require_relative '../analysis/pipeline'
require_relative '../github/client'
require_relative '../github/comment_generator'
require_relative '../github/cloner'

module Diggit
  module Jobs
    class AnalyseProject < Que::Job
      def run(project_id, pull, head:, base:)
        @project = Project.find(project_id)
        @comment_generator = Github::CommentGenerator.
          new(project.gh_path, pull, Github.client)

        return unless project && project.watch

        Que.log(message: "Cloning #{project.gh_path}...")
        clone do |repo|
          pipeline = Analysis::Pipeline.new(repo, head: head, base: base)
          pipeline.aggregate_comments.each { |comment| create_comment(comment) }
        end

        Que.log(message: 'Sending comments to github...')
        comment_generator.send
      end

      private

      attr_reader :project, :comment_generator
      delegate :add_comment, :add_comment_on_file, to: :comment_generator

      def clone(&block)
        Github::Cloner.new(project.ssh_private_key).clone(project.gh_path, &block)
      end

      def create_comment(message:, location: nil)
        return add_comment(message) if location.nil?

        _, file, line = *location.match(/^(.+):(\d+)$/)
        add_comment_on_file(message, file, line.to_i)
      end
    end
  end
end
