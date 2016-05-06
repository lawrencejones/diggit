require 'que'

require_relative '../jobs/poll_github'
require_relative '../models/pull_analysis'
require_relative '../models/project'

module Diggit
  module Services
    # Uses Que to schedule the PollGithub job on regular intervals. Only one POLL_JOB is
    # to be enqueued at any time.
    class GithubPoller
      POLLING_INTERVAL = 30 # seconds
      POLL_JOB = Jobs::PollGithub

      def self.start
        @poller = Thread.new do
          loop do
            Jobs::PollGithub.enqueue unless already_queued?
            sleep(POLLING_INTERVAL)
          end
        end
      end

      def self.already_queued?
        job_status = Que.job_stats.find { |job| job['job_class'] == POLL_JOB.to_s }
        job_status.present? && (job_status['count'] + job_status['count_working']) > 0
      end

      def self.kill
        @poller.kill unless @poller.nil?
        @poller = nil
      end
    end
  end
end
