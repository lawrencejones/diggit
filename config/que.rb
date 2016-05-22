require 'bundler/setup'
Bundler.require(:default)

require_relative '../lib/diggit/system'
Diggit::System.init

Que.error_handler = proc do |error, job|
  Rollbar.error(error, job, "Error in Que job #{job['job_class']}")
end

Dir[File.join(Diggit::System::JOBS_PATH, '*.rb')].each { |r| require_relative(r) }
