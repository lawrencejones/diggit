set :branch, 'master'
set :stage, 'production'

server 'diggit.production', user: 'deploy', roles: %w(web app)
