require 'que'

require_relative '../models/project'
require_relative '../github/repo'

module Diggit
  module Jobs
    # Configures the projects github repo to subscribe to webhooks and loads the
    # application deploy key, to enable pulling.
    class ConfigureProjectGithub < Que::Job
      def run(project_id, gh_token)
        project = Project.find(project_id)
        return unless project.watch

        repo = Github::Repo.from_path(project.gh_path,
                                      Octokit::Client.new(access_token: gh_token))

        Que.log(message: "Configuring deploy key on #{project.gh_path}...")
        project.generate_keypair! unless project.keys?
        repo.setup_deploy_key!(title: "Diggit - #{env}", key: project.ssh_public_key)

        Que.log(message: "Configuring webhooks on #{project.gh_path}...")
        repo.setup_webhook!(webhook_endpoint)

      rescue ActiveRecord::RecordNotFound
        Que.log(level: :error, message: "Failed to find project with id=#{project_id}")
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
