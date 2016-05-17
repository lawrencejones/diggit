require 'que'

module Diggit
  module Jobs
    # Super simple repeating jobs, schedules the successor INTERVAL seconds after
    # finishing a run.
    class RepeatJob < Que::Job
      INTERVAL = 10 # seconds, default to override in subclasses

      def _run
        super.tap { reenqueue }
      end

      def reenqueue
        return if in_queue?

        rerun_at = now.advance(seconds: INTERVAL.to_i)
        self.class.enqueue(*attrs[:args], run_at: rerun_at)
      end

      def now
        Que.execute('SELECT now();').first['now']
      end

      def in_queue?
        result = Que.execute(<<-SQL)
        SELECT COUNT(*)
          FROM que_jobs
         WHERE job_class='#{self.class}';
        SQL
        result.first['count'] > 0
      end
    end
  end
end
