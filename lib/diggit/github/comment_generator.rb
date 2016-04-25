require 'active_support/core_ext/module'
require_relative './diff'

module Diggit
  module Github
    class CommentGenerator
      def initialize(repo, pull, client)
        @repo = repo
        @pull = pull
        @client = client

        @diff = Diff.from_pull_request(repo, pull, client)
        @comments = []
        @comments_by_file = {}
      end

      # Batch and send comments to github
      def push
        @client.add_comment(repo, pull, comments.join("\n")) unless comments.empty?
        comments_by_file.each do |file_diff_index, comments|
          _, file, diff_index = *file_diff_index.match(/^(.+):(\d+)$/)
          body = comments.join("\n")

          @client.create_pull_comment(repo, pull, body, diff.head, file, diff_index.to_i)
        end
      end

      def add_comment(body)
        comments << body
      end

      def add_comment_on_file(body, file, line = 1)
        # If we can't locate this exact line, then tag the comment to the first line
        # of the diff chunk. Best effort attempt if the diff isn't playing ball.
        diff_index = diff.index_for(file, line) || 1
        comments = comments_by_file["#{file}:#{diff_index}"] ||= []
        comments << body

      rescue Diff::FileNotFound
        add_comment("At #{file}:#{line} - #{body}")
      end

      private

      attr_reader :repo, :pull, :diff, :comments, :comments_by_file
    end
  end
end
