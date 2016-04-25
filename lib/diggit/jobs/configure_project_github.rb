require 'que'

require_relative '../logger'
require_relative '../models/project'
require_relative '../github/repo'

module Diggit
  module Jobs
    # Configures the projects github repo to subscribe to webhooks and loads the
    # application deploy key, to enable pulling.
    class ConfigureProjectGithub < Que::Job
      include InstanceLogger

      def run(project_id, gh_token)
        project = Project.find(project_id)
        return unless project.watch

        gh_client = Octokit::Client.new(access_token: gh_token)
        repo = Github::Repo.from_path(project.gh_path, gh_client)

        info { "Set #{Github.login} as collaborator..." }
        repo.add_collaborator(Github.login)

        info { "Configuring deploy key on #{project.gh_path}..." }
        project.generate_keypair! unless project.keys?
        repo.setup_deploy_key!(title: "Diggit - #{env}", key: project.ssh_public_key)

        info { "Configuring webhooks on #{project.gh_path}..." }
        repo.setup_webhook!(webhook_endpoint)
        destroy

      rescue ActiveRecord::RecordNotFound
        error { "Failed to find project with id=#{project_id}" }
      end

      private

      def env
        Prius.get(:diggit_env)
      end

      def webhook_endpoint
        Prius.get(:diggit_webhook_endpoint)
      end
    end
  end
end
