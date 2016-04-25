require 'diggit/jobs/configure_project_github'

RSpec.describe(Diggit::Jobs::ConfigureProjectGithub) do
  subject(:run!) { described_class.new({}).run(project_id, gh_token) }
  let(:gh_token) { 'gh-token' }

  before do
    allow(Prius).to receive(:get) do |env_key|
      { diggit_env: 'prod',
        diggit_github_token: 'github-token',
        diggit_webhook_endpoint: 'https://diggit.com/api/github_webhooks' }.fetch(env_key)
    end
  end

  context "when project doesn't exist" do
    let(:project_id) { 999 }

    it 'exits early and never contacts github' do
      expect(Diggit::Github::Repo).not_to receive(:from_path)
      run!
    end

    it 'logs error' do
      expect(Diggit.logger).to receive(:error) do |_, &block|
        expect(block.call).to eql('Failed to find project with id=999')
      end
      run!
    end
  end

  context 'when project exists' do
    let(:project) { FactoryGirl.create(:project, :diggit) }
    let(:project_id) { project.id }
    let(:repo) { instance_double(Diggit::Github::Repo) }

    before do
      allow(Diggit::Github::Repo).
        to receive(:from_path).
        with(project.gh_path, anything).
        and_return(repo)
    end

    context 'with watch=true' do
      let(:watch) { true }
      before { allow(Diggit::Github).to receive(:login).and_return('diggit-bot') }

      it 'configures collaborator, deploy keys, webhooks', :aggregate_failure do
        expect(repo).
          to receive(:add_collaborator).
          with('diggit-bot')
        expect(repo).
          to receive(:setup_deploy_key!).
          with(title: 'Diggit - prod', key: anything)
        expect(repo).
          to receive(:setup_webhook!).
          with('https://diggit.com/api/github_webhooks')
        run!
      end
    end
  end
end
