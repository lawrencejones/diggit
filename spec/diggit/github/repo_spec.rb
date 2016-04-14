require 'diggit/github/repo'

RSpec.describe(Diggit::Github::Repo) do
  subject(:repo) { described_class.new(repo_payload, gh_client) }

  let(:repo_payload) { load_json_fixture('github_client/repo.json').deep_symbolize_keys }
  let(:gh_client) { instance_double(Octokit::Client) }
  let(:repo_path) { repo_payload[:full_name] }

  let(:endpoint) { 'https://diggit.com/api/github_webhooks' }

  describe '#setup_webhook!' do
    context 'when webhook does not exist' do
      before { allow(repo).to receive(:existing_webhook).and_return(nil) }

      it 'calls create hook' do
        expect(gh_client).
          to receive(:create_hook).
          with(repo_payload[:full_name], 'web',
               hash_including(url: endpoint),
               hash_including(active: true, events: ['pull_request']))
        repo.setup_webhook!(endpoint)
      end
    end

    context 'when webhook already exists' do
      before { allow(repo).to receive(:existing_webhook).and_return(true) }

      it 'does not create_hook' do
        expect(gh_client).not_to receive(:create_hook)
        repo.setup_webhook!(endpoint)
      end
    end
  end

  describe '#existing_webhook' do
    before do
      allow(gh_client).to receive(:hooks).with(repo_path).and_return [
        { id: 1, config: { url: 'https://an-endpoint.com' } },
        { id: 2, config: { url: endpoint } },
      ]
    end

    context 'for webhook that exists' do
      it 'finds webhook' do
        expect(repo.existing_webhook(endpoint)).to include(id: 2)
      end
    end

    context 'for webhook that does not exist' do
      it 'returns nil' do
        expect(repo.existing_webhook('https://not-an-endpoint.com')).to be_nil
      end
    end
  end

  describe '#remove_webhook!' do
    context 'when webhook exists' do
      before { allow(repo).to receive(:existing_webhook).and_return(id: 999) }

      it 'removes hook' do
        expect(gh_client).to receive(:remove_hook).with(repo_path, 999)
        repo.remove_webhook!(endpoint)
      end
    end

    context 'when webhook does not exist' do
      before { allow(repo).to receive(:existing_webhook).and_return(nil) }

      it 'does not remove hook' do
        expect(gh_client).not_to receive(:remove_hook)
        repo.remove_webhook!(endpoint)
      end
    end
  end

  describe '#setup_deploy_key!' do
    let(:key) { 'ssh-private-key' }

    context 'when key exists' do
      before do
        allow(repo).
          to receive(:existing_deploy_key).
          with(key).and_return(true)
      end

      it 'does not add_deploy_key' do
        expect(gh_client).not_to receive(:add_deploy_key)
      end
    end
  end
end
