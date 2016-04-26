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
          file, diff_index = parse_location(file_diff_index)
          body = comments.join("\n")

          @client.create_pull_comment(repo, pull, body, diff.head, file, diff_index)
        end
      end

      # Optional location field that will delegate to add_comment_on_file, to allow
      # add_comment('message', 'file.rb:4') for example.
      def add_comment(body, location = nil)
        return comments << body if location.nil?

        add_comment_on_file(body, *parse_location(location))
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

      def pending
        thread_comments = comments.empty? ? 0 : 1
        thread_comments + comments_by_file.keys.count
      end

      private

      attr_reader :repo, :pull, :diff, :comments, :comments_by_file

      def parse_location(location)
        return if location.nil?

        file, line = location.split(/:(?=\d+$)/)
        [file, line.to_i]
      end
    end
  end
end
