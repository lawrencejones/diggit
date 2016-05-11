require 'octokit'
require_relative '../../../config/prius'

module Diggit
  module Github
    # Authenticated Github client as diggit-bot
    def self.client
      @client ||= Octokit::Client.new(access_token: Prius.get(:diggit_github_token))
    end

    # Ideally diggit-bot
    def self.login
      @login ||= client.user[:login]
    end

    # Returns the appropriate Github client for the given project
    def self.client_for(project)
      return Github.client if project.gh_token.nil?
      Octokit::Client.new(access_token: project.gh_token)
    end
  end
end
