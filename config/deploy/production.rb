set :branch, 'master'
set :stage, 'production'

server '178.62.124.191', user: 'deploy', roles: %w(web app)
server '146.169.47.204', user: 'worker', roles: %w(worker)
