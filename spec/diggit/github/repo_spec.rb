require 'diggit/github/repo'

RSpec.describe(Diggit::Github::Repo) do
  subject(:repo) { described_class.new(repo_payload, gh_client) }

  let(:repo_payload) { load_json_fixture('github_client/repo.json').deep_symbolize_keys }
  let(:gh_client) { instance_double(Octokit::Client) }

  describe '#setup_webhook!' do
    let(:endpoint) { 'https://diggit.com/api/github_webhooks' }

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

  describe '#remove_webhook!' do
    let(:endpoint) { 'https://diggit.com/api/github_webhooks' }

    context 'when webhook does not exist' do
      before { allow(repo).to receive(:existing_webhook).and_return(nil) }

      it 'does not remove hook' do
        expect(gh_client).not_to receive(:remove_hook)
        repo.remove_webhook!(endpoint)
      end
    end
  end
end
