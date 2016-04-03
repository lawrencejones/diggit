require 'prius'

Prius.load(:diggit_env, env_var: 'RACK_ENV')
Prius.load(:diggit_host)
Prius.load(:diggit_secret)
Prius.load(:diggit_github_token)
Prius.load(:diggit_github_client_id)
Prius.load(:diggit_github_client_secret)
