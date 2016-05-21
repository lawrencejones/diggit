require 'bundler/setup'
Bundler.setup(:default, ENV['RACK_ENV'])

require 'rollbar/middleware/sinatra'
require_relative 'lib/diggit/system'

use(Rollbar::Middleware::Sinatra)
run(Diggit::System.rack_app)

require_relative 'lib/diggit/jobs/poll_github'
Diggit::Jobs::PollGithub.enqueue

require_relative 'lib/diggit/jobs/daily_analysis_summary'
Diggit::Jobs::DailyAnalysisSummary.schedule
