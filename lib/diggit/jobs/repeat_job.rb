require 'que'

module Diggit
  module Jobs
    # Super simple repeating jobs, schedules the successor INTERVAL seconds after
    # finishing a run.
    class RepeatJob < Que::Job
      INTERVAL = 10 # seconds, default to override in subclasses

      def _run
        super
        self.class.enqueue(*attrs[:args],
                           run_at: Time.now.advance(seconds: INTERVAL.to_i))
      end
    end
  end
end
