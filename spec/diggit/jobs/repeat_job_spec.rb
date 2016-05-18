require 'diggit/jobs/repeat_job'

RSpec.describe(Diggit::Jobs::RepeatJob) do
  class MockRepeatJob < Diggit::Jobs::RepeatJob
    INTERVAL = 10
  end
  subject(:job) { MockRepeatJob.new({}) }
  let(:job_class) { MockRepeatJob.to_s }

  def job_counts
    Que.job_stats.map { |stat| stat.values_at('job_class', 'count') }.to_h
  end

  describe '.run' do
    context 'without job already queued' do
      it 'reenqueues the job for INTERVAL seconds after current time' do
        job._run
        expect(job_counts[job_class]).to equal(1)

        run_ats = Que.execute(<<-SQL).map { |row| row['timezone'] }
        SELECT run_at AT TIME ZONE 'UTC'
          FROM que_jobs
         WHERE job_class='#{job_class}';
        SQL

        now = job.now
        expected_next_run_at = now.advance(seconds: MockRepeatJob::INTERVAL)
        next_run_at = run_ats.first.in_time_zone

        expect(next_run_at.to_i).
          to be_within(1).
          of(expected_next_run_at.to_i)
      end
    end

    context 'when there is job already queued' do
      before { MockRepeatJob.enqueue }

      it 'does not reenqueue job' do
        initial_count = job_counts[job_class]
        job._run
        expect(job_counts[job_class]).to equal(initial_count)
      end
    end
  end
end
