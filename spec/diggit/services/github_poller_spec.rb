require 'diggit/services/github_poller'

RSpec.describe(Diggit::Services::GithubPoller) do
  subject(:poller) { described_class }

  before do
    # Mock Thread.new to prevent escaping the current thread
    allow(Thread).
      to receive(:new).
      and_yield.
      and_return(instance_double(Thread).as_null_object)

    # Capture block given to loop
    allow(poller).to receive(:loop) { |&block| @poll_block = block }
    stub_const("#{poller}::POLLING_INTERVAL", 0)
  end

  after { poller.kill }

  describe '.start' do
    before { poller.start }
    before { allow(poller).to receive(:already_queued?).and_return(already_queued) }

    context 'when PollGithub is not currently running or queued' do
      let(:already_queued) { false }

      it 'enqueues new job' do
        expect(Diggit::Jobs::PollGithub).to receive(:enqueue)
        @poll_block.call
      end
    end

    context 'when PollGithub is already queued' do
      let(:already_queued) { true }

      it 'does not enqueue job' do
        expect(Diggit::Jobs::PollGithub).not_to receive(:enqueue)
        @poll_block.call
      end
    end
  end

  describe '.already_queued?' do
    subject { poller.already_queued? }

    context 'when PollGithub is already enqueued' do
      before { Diggit::Jobs::PollGithub.enqueue }
      it { is_expected.to be(true) }
    end

    context 'when PollGithub is not enqueued' do
      it { is_expected.to be(false) }
    end
  end
end
