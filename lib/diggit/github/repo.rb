module Diggit
  module Github
    class Repo
      def self.from_path(gh_path, client)
        new(client.repo(gh_path), client)
      end

      def initialize(repo_payload, client)
        @repo = repo_payload
        @client = client
      end

      def path
        @repo[:full_name]
      end

      def setup_webhook!(endpoint)
        return unless existing_webhook(endpoint).nil?

        @client.create_hook(
          path, 'web',
          { url: endpoint, content_type: :json },
          events: ['pull_request'],
          active: true)
      end

      def remove_webhook!(endpoint)
        webhook = existing_webhook(endpoint)
        return true if webhook.nil?

        @client.remove_hook(path, webhook[:id])
      end

      def existing_webhook(endpoint)
        @client.hooks(path).find do |hook|
          hook[:config].to_h.fetch(:url, '').match(endpoint)
        end
      end

      def setup_deploy_key!(title:, key:)
        return unless existing_deploy_key(key).nil?
        @client.add_deploy_key(path, title, key)
      end

      def existing_deploy_key(key)
        key_without_machine = key.match(/ssh-rsa \S+/).to_s || ''

        @client.deploy_keys(path).find do |deploy_key|
          deploy_key[:key] == key_without_machine
        end
      end
    end
  end
end
