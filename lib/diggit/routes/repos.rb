require 'coach'

require_relative '../middleware/authorize'
require_relative '../middleware/github_client'

module Diggit
  module Routes
    module Repos
      class Index < Coach::Middleware
        uses Middleware::Authorize
        uses Middleware::GithubClient

        requires :gh_client

        def call
          [200, {}, [{ repos: github_repos }.to_json]]
        end

        private

        def github_repos
          @github_repos = gh_client.repos.map do |repo|
            { gh_path: repo[:full_name], private: repo[:private],
              project_id: project_ids[repo[:full_name]] }
          end
        end

        def project_ids
          @project_ids ||= Hash[Project.pluck(:gh_path, :id)]
        end
      end
    end
  end
end
