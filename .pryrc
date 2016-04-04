Pry.config.prompt = [proc { 'diggit> ' }]
require './lib/diggit/system'
Diggit::System.init

gh_token = ENV['DIGGIT_GITHUB_TOKEN']
gh_client = Octokit::Client.new(access_token: gh_token) if gh_token.present?
