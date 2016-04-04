require_relative './authorize'
require_relative '../github/repo'
require_relative './github_client'

module Diggit
  module Middleware
    class GithubRepoPermissions < Coach::Middleware
      uses GithubClient

      requires :gh_client
      provides :gh_repo

      def call
        unless repo_permissions?
          fail Middleware::Authorize::NotAuthorized, 'github_permissions'
        end

        provide(gh_repo: Github::Repo.new(repo, gh_client))
        next_middleware.call
      end

      private

      def repo
        @repo ||= gh_client.repo(repo_path)
      end

      def repo_permissions?
        gh_repo = gh_client.repo(repo_path)
        missing = required_permissions.select { |key| !gh_repo[:permissions][key] }
        missing.empty?

      rescue Octokit::NotFound
        false
      end

      def required_permissions
        config.fetch(:requires)
      end

      def repo_path
        "#{params[:owner]}/#{params[:repo]}"
      end
    end
  end
end
