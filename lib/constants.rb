module Constants
  DOMAIN = Prius.get(:diggit_domain).freeze
  GITHUB_TOKEN = Prius.get(:diggit_github_token).freeze
  WEBHOOK_ENDPOINT = "#{Prius.get(:diggit_domain)}/github/webhooks".freeze
end
