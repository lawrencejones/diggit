require 'octokit'
require_relative '../../../config/prius'

module Diggit
  module Github
    # Authenticated github client as diggit-bot
    def self.client
      @client ||= Octokit::Client.new(access_token: Prius.get(:diggit_github_token))
    end
  end
end
