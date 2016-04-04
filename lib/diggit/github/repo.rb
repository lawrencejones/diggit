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

      def setup_webhooks!(endpoint)
        return if webhook_already_setup?(endpoint)

        puts("Setting up webhooks on #{path}...")
        @client.create_hook(
          path, 'web',
          { url: endpoint, content_type: :json },
          events: ['pull_request'],
          active: true)
      end

      def webhook_already_setup?(endpoint)
        @client.hooks(path).select do |hook|
          hook[:config].to_h.fetch(:url, '').match(endpoint)
        end.any?
      end
    end
  end
end
