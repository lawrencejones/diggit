require 'octokit'

module Diggit
  module Middleware
    class GithubClient < Coach::Middleware
      requires :gh_token
      provides :gh_client

      def call
        provide(gh_client: gh_client)
        next_middleware.call
      end

      def gh_client
        Octokit::Client.new(access_token: gh_token, auto_paginate: true)
      end
    end
  end
end
