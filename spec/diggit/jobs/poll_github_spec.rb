require 'diggit/jobs/poll_github'

RSpec.describe(Diggit::Jobs::PollGithub) do
  subject(:job) { described_class.new({}) }
  let(:run!) { job.run }

  let!(:diggit) { FactoryGirl.create(:project, :diggit, watch: true, polled: false) }
  let!(:payments_service) do
    FactoryGirl.
      create(:project,
             gh_path: 'gocardless/payments_service',
             watch: true, polled: true)
  end

  let(:gh_client) { instance_double(Octokit::Client) }
  before do
    allow(Diggit::Github).to receive(:client).and_return(gh_client)
    allow(Diggit::Jobs::AnalysePull).to receive(:enqueue)
    allow(gh_client).to receive(:pulls)
  end

  def mock_pull(project, number, head:, base:)
    { head: { sha: head, repo: { full_name: project.gh_path } },
      base: { sha: base }, number: number }
  end

  describe '.run' do
    let(:head) { 'head-sha' }
    before do
      allow(gh_client).
        to receive(:pulls).
        with(payments_service.gh_path).
        and_return([mock_pull(payments_service, 1, base: 'base-sha', head: head)])
    end

    it 'does not poll github for non-polled projects' do
      expect(gh_client).not_to receive(:pulls).with(diggit.gh_path)
      run!
    end

    context 'when polled project has pulls that have not been analysed' do
      it 'enqueues analysis' do
        expect(Diggit::Jobs::AnalysePull).
          to receive(:enqueue).
          with(payments_service.gh_path, 1, head, 'base-sha')
        run!
      end
    end

    context 'when pull has been analysed but there are new commits' do
      let(:head) { 'new-head-sha' }
      let!(:existing_analysis) do
        FactoryGirl.create(:pull_analysis,
                           project: payments_service,
                           pull: 1,
                           base: 'base-sha',
                           head: 'head-sha')
      end

      it 'enqueues analysis' do
        expect(Diggit::Jobs::AnalysePull).
          to receive(:enqueue).
          with(payments_service.gh_path, 1, head, 'base-sha')
        run!
      end
    end
  end
end
