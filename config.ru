require 'bundler/setup'
Bundler.setup(:default, ENV['RACK_ENV'])

require 'rollbar/middleware/sinatra'
require_relative 'lib/diggit/system'

# Prevent Passenger hanging when forking for the que workers
if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    Que.mode = :async if forked
    Que.error_handler = proc do |error, job|
      Rollbar.error(error, job, "Error in Que job #{job['job_class']}")
    end
  end
end

use(Rollbar::Middleware::Sinatra)
run(Diggit::System.rack_app)

require_relative 'lib/diggit/services/github_poller'
Diggit::Services::GithubPoller.start
