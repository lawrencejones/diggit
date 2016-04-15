# vi:syntax=ruby
require 'pry'
require 'logger'
require 'que'

Pry.config.prompt = [proc { 'diggit> ' }]

require './lib/diggit/system'
Diggit::System.init

Que.mode = :sync
Que.logger = Logger.new(STDOUT)
Que.logger.level = Logger::INFO.to_i

gh_token = ENV['DIGGIT_GITHUB_TOKEN']
require_relative 'lib/diggit/github/client'
gh_client = Diggit::Github.client
