require 'coach'
require_relative '../serializers/project_serializer'
require_relative '../jobs/configure_project_github'
require_relative '../middleware/authorize'
require_relative '../middleware/github_repo_permissions'
require_relative '../middleware/json_schema_validation'

module Diggit
  module Routes
    module Projects
      class Index < Coach::Middleware
        uses Middleware::Authorize
        uses Middleware::GithubClient

        requires :gh_client

        def call
          [200, {}, [{ projects: projects_from_github }.to_json]]
        end

        private

        def projects_from_github
          @projects_from_github ||= repos_with_admin_and_pull.
            map do |repo|
              { gh_path: repo[:full_name],
                private: repo[:private],
                watch: watched_projects.include?(repo[:full_name]) }
            end
        end

        def repos_with_admin_and_pull
          gh_client.repos(nil, sort: :pushed, direction: :desc).
            select { |repo| repo[:permissions][:admin] && repo[:permissions][:pull] }
        end

        def watched_projects
          @watched_projects ||= Project.where(watch: true).pluck(:gh_path)
        end
      end

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

        requires :gh_token, :gh_repo_path

        def call
          ActiveRecord::Base.transaction do
            project = update_project!
            Jobs::ConfigureProjectGithub.enqueue(project.id, gh_token)

            return [201, {}, [{ projects: serialize(project) }.to_json]]
          end
        end

        private

        def serialize(project)
          Serializers::ProjectSerializer.new(project).as_json
        end

        def update_project!
          project = Project.find_or_initialize_by(gh_path: gh_repo_path)
          project.update!(params.fetch('projects'))
          project
        end
      end
    end
  end
end
