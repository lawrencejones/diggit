require 'diggit/jobs/cron_job'

RSpec.describe(Diggit::Jobs::CronJob) do
  class MockJob < Diggit::Jobs::CronJob; end
  subject(:job_class) do
    stub_const('MockJob::SCHEDULE_AT', schedule_at)
    MockJob
  end

  before { allow(job_class).to receive(:postgres_now).and_return(stubbed_now) }
  let(:schedule_at) { ['10:00', '11:00', '12:00'] }

  describe '.next_start_end' do
    subject(:start_end) { job_class.next_start_end }
    let(:tomorrow) { stubbed_now.advance(days: 1) }

    let(:start_at) { start_end[0] }
    let(:end_at) { start_end[1] }

    context 'when next period is today' do
      let(:stubbed_now) { Time.parse('10:30') }

      it 'returns start and end of next period' do
        expect(start_at.to_date).to eql(stubbed_now.to_date)
        expect(end_at.to_date).to eql(stubbed_now.to_date)

        expect(start_at.strftime('%H:%M')).to eql('11:00')
        expect(end_at.strftime('%H:%M')).to eql('12:00')
      end
    end

    context 'when next end is tomorrow' do
      let(:stubbed_now) { Time.parse('11:30') }

      it 'computes end_at to be tomorrow' do
        expect(start_at.to_date).to eql(stubbed_now.to_date)
        expect(end_at.to_date).to eql(tomorrow.to_date)

        expect(start_at.strftime('%H:%M')).to eql('12:00')
        expect(end_at.strftime('%H:%M')).to eql('10:00')
      end
    end

    context 'when next period is tomorrow' do
      let(:stubbed_now) { Time.parse('13:00') }

      it 'computes start and end to be tomorrow' do
        expect(start_at.to_date).to eql(tomorrow.to_date)
        expect(end_at.to_date).to eql(tomorrow.to_date)

        expect(start_at.strftime('%H:%M')).to eql('10:00')
        expect(end_at.strftime('%H:%M')).to eql('11:00')
      end
    end
  end
end
