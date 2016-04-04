require 'coach'
require_relative '../middleware/authorize'
require_relative '../middleware/github_repo_permissions'
require_relative '../middleware/json_schema_validation'

module Diggit
  module Routes
    module Projects
      class Update < Coach::Middleware
        uses Middleware::Authorize
        uses Middleware::GithubRepoPermissions, requires: [:admin, :pull]
        uses Middleware::JsonSchemaValidation, schema: {
          type: :object,
          required: ['projects'],
          properties: {
            projects: {
              type: :object,
              additionalProperties: false,
              properties: {
                watch: { type: :boolean },
              },
            },
          },
        }

        requires :gh_repo

        def call
          ActiveRecord::Base.transaction do
            project = update_project!
            gh_repo.setup_webhooks!(webhook_endpoint)

            return [201, {}, [{ projects: project.as_json }.to_json]]
          end
        rescue Octokit::Error
          return [500, {}, [{ error: 'github_client_failure' }.to_json]]
        end

        private

        def update_project!
          project = Project.find_or_initialize_by(gh_path: gh_repo.path)
          project.update!(params.fetch('projects'))
          project
        end

        def webhook_endpoint
          config.fetch(:webhook_endpoint)
        end
      end
    end
  end
end
