set :branch, `git rev-parse --abbrev-ref HEAD`.chomp
set :stage, 'production'

server '178.62.124.191', user: 'deploy', roles: %w(web app worker)
