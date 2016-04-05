module Diggit
  module Github
    class Repo
      def initialize(repo_payload, client)
        @repo = repo_payload
        @client = client
      end

      def path
        @repo[:full_name]
      end

      def setup_webhook!(endpoint)
        return unless existing_webhook(endpoint).nil?

        puts("Setting up webhook on #{path}...")
        @client.create_hook(
          path, 'web',
          { url: endpoint, content_type: :json },
          events: ['pull_request'],
          active: true)
      end

      def remove_webhook!(endpoint)
        webhook = existing_webhook(endpoint)
        return true if webhook.nil?

        puts("Removing webhook on #{path}...")
        @client.remove_hook(path, webhook[:id])
      end

      def existing_webhook(endpoint)
        @client.hooks(path).find do |hook|
          hook[:config].to_h.fetch(:url, '').match(endpoint)
        end
      end
    end
  end
end
