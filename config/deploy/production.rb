set :branch, 'master'
set :stage, 'production'

server '178.62.124.191', user: 'deploy', roles: %w(web app worker)
