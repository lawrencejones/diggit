require 'que'

module Diggit
  module Jobs
    class CronJob < Que::Job
      # To be defined in subclasses as HH:MM times to run this job
      SCHEDULE_AT = [].freeze

      def self.schedule
        start_at, end_at = next_start_end
        enqueue({ start_at: start_at.to_f, end_at: end_at.to_f }, run_at: start_at)
      end

      # Computes the next time period with which to schedule this job.
      def self.next_start_end
        now = postgres_now
        schedule_times.drop_while { |time| time < now }.first(2)
      end

      # Generates list of todays schedule times, appending two times for the first runs
      # tomorrow.
      def self.schedule_times
        times = self::SCHEDULE_AT.map do |time_string|
          Time.zone.parse(time_string)
        end.sort
        times.push(*times.first(2).map { |t| t.advance(days: 1) })
        times
      end

      def self.postgres_now
        Que.execute('SELECT now();').first['now']
      end

      attr_reader :start_at, :end_at, :time_range

      def _run
        args = attrs[:args].first

        @start_at = Time.zone.at(args.delete('start_at'))
        @end_at = Time.zone.at(args.delete('end_at'))
        @time_range = @start_at...@end_at

        attrs[:args].shift if args.empty?

        super

        self.class.schedule
      end
    end
  end
end
