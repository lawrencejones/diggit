require 'diggit/jobs/repeat_job'

RSpec.describe(Diggit::Jobs::RepeatJob) do
  subject(:job) { described_class.new({}) }
  let(:job_class) { described_class.to_s }

  def job_counts
    Que.job_stats.map { |stat| stat.values_at('job_class', 'count') }.to_h
  end

  describe '.run' do
    context 'without job already queued' do
      it 'reenqueues the job for INTERVAL seconds after current time' do
        job._run
        expect(job_counts[job_class]).to equal(1)

        run_ats = Que.execute(<<-SQL)
        SELECT run_at
          FROM que_jobs
         WHERE job_class='#{job_class}';
        SQL

        now = job.now
        expected_next_run_at = now.advance(seconds: described_class::INTERVAL)
        next_run_at = Time.zone.parse(run_ats.first['run_at'])

        expect(next_run_at.to_i).
          to be_within(1).
          of(expected_next_run_at.to_i)
      end
    end

    context 'when there is job already queued' do
      before { described_class.enqueue }

      it 'does not reenqueue job' do
        initial_count = job_counts[job_class]
        job._run
        expect(job_counts[job_class]).to equal(initial_count)
      end
    end
  end
end
