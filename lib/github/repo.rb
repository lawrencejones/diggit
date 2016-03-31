require 'github/client'

module Github
  class Repo
    def initialize(github_path)
      @github_path = github_path
      fail "Could not access repo at #{github_path}" unless exists?
    end

    attr_reader :github_path

    def setup_webhooks(webhook_endpoint)
      return if webhook_already_setup?(webhook_endpoint)
      Github.client.create_hook(
        github_path, 'web',
        { url: webhook_url, content_type: :json },
        events: ['pull_request'],
        active: true
      )
    end

    def exists?
      Github.client.repo(github_path)
    rescue Octokit::NotFound
      false
    end

    def webhook_already_setup?(webhook_endpoint)
      Github.client.hooks(github_path).any? do |hook|
        hook.fetch(:config, {}).fetch(:url, '').match(webhook_endpoint)
      end
    end
  end
end
