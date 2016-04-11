require 'active_support/core_ext/module'
require_relative './diff'

module Diggit
  module Github
    class CommentGenerator
      def initialize(repo, pull_request_id, client)
        @repo = repo
        @pull_request_id = pull_request_id
        @client = client
      end

      private

      delegate :head, :base, to: :pull_request

      def diff
        @diff ||= Diff.new(@client.compare(@repo, base.sha, head.sha,
                                           accept: 'application/vnd.github.v3.diff'))
      end

      def pull_request
        @pull_request ||= @client.pull_request(@repo, @pull_request_id)
      end
    end
  end
end
