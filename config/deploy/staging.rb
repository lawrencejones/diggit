set :branch, `git rev-parse --abbrev-ref HEAD`.chomp
set :stage, 'production'

server 'diggit.production', user: 'deploy', roles: %w(web app)
