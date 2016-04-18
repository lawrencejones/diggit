require 'prius'
require 'dotenv'

Dotenv.load('./dummy-env') unless ENV['RACK_ENV'] == 'production'
Dotenv.load('./env') if File.exist?('./env')

Prius.load(:diggit_env, env_var: 'RACK_ENV')
Prius.load(:diggit_host)
Prius.load(:diggit_secret)
Prius.load(:diggit_github_token)
Prius.load(:diggit_github_client_id)
Prius.load(:diggit_github_client_secret)
Prius.load(:diggit_webhook_endpoint)
