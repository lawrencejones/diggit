require 'octokit'
require 'diggit/routes/projects'

RSpec.describe(Diggit::Routes::Projects) do
  subject(:instance) { described_class.new(context, null_middleware, config) }
  let(:config) { { webhook_endpoint: 'https://diggit.com/api/projects/webhooks' } }

  let(:context) { { request: request, gh_client: gh_client, gh_repo: gh_repo } }
  let(:request) { mock_request_for(url, params: params, method: method) }
  let(:params) { nil }

  let(:gh_client) { instance_double(Octokit::Client) }
  let(:gh_repo) do
    instance_double(Diggit::Github::Repo, path: 'lawrencejones/diggit')
  end

  let(:json_body) { JSON.parse(instance.call[2].join) }

  describe(described_class::Index) do
    let(:url) { 'https://diggit.com/api/projects' }
    let(:method) { 'GET' }

    let(:repos_fixture) { load_json_fixture('github_client/repos.json') }
    before do
      allow(gh_client).
        to receive(:repos).
        and_return(repos_fixture.map(&:deep_symbolize_keys))
    end

    it { is_expected.to respond_with_status(200) }
    it do
      is_expected.
        to respond_with_json('projects' => [
                              { 'gh_path' => 'lawrencejones/librespot',
                                'private' => false,
                                'watch' => false },
                              { 'gh_path' => 'lawrencejones/BearwavesWebsite',
                                'private' => false,
                                'watch' => false },
                              { 'gh_path' => 'lawrencejones/LiveHack',
                                'private' => false,
                                'watch' => false },
                            ])
    end

    context 'when a project is being watched' do
      let!(:librespot) { Project.create(gh_path: 'lawrencejones/librespot') }
      let(:json_response) { JSON.parse(instance.call[2].join) }

      it 'marks watch:true' do
        serialized_librespot = json_response['projects'].
          find { |repo| repo['gh_path'] == librespot.gh_path }
        expect(serialized_librespot).to include('watch' => true)
      end
    end
  end

  describe(described_class::Update) do
    let(:url) { 'https://diggit.com/api/projects/lawrencejones/diggit' }
    let(:method) { 'PUT' }
    let(:params) { { projects: { watch: false } }.deep_stringify_keys }

    before do
      allow(gh_repo).to receive(:setup_webhook!).and_return(nil)
      allow(gh_repo).to receive(:remove_webhook!).and_return(true)
    end

    it_behaves_like 'passes JSON schema', 'api/projects/update.fixture.json'

    context 'when project already exists' do
      let!(:project) { Project.create(gh_path: 'lawrencejones/diggit', watch: true) }

      it 'updates project watch field' do
        expect { instance.call }.to change { project.reload.watch }
      end

      it 'removes webhook' do
        expect(gh_repo).
          to receive(:remove_webhook!).
          with(config.fetch(:webhook_endpoint))
        instance.call
      end

      it { is_expected.to respond_with_status(201) }
      it { is_expected.to respond_with_body_that_matches(/"watch":false/i) }
    end

    context "when project doesn't exist" do
      it 'creates new project' do
        expect { instance.call }.to change(Project, :count).by(1)
      end

      it { is_expected.to respond_with_status(201) }
      it { is_expected.to respond_with_body_that_matches(/"watch":false/i) }
    end

    context 'when github fails' do
      before do
        allow(gh_repo).
          to receive(:remove_webhook!).
          and_raise(Octokit::Unauthorized)
      end

      it 'does not create new project' do
        expect { instance.call }.not_to change(Project, :count)
      end

      it { is_expected.to respond_with_status(500) }
      it { is_expected.to respond_with_body_that_matches(/github_client_failure/) }
    end
  end
end
