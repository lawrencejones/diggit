require 'octokit'
require 'diggit/github/repo'
require 'diggit/middleware/github_repo_permissions'

RSpec.describe(Diggit::Middleware::GithubRepoPermissions) do
  subject(:instance) { described_class.new(context, null_middleware, config) }

  let(:context) { { request: request, gh_client: gh_client } }
  let(:request) { mock_request_for(url, params: { owner: 'owner', repo: 'repo' }) }
  let(:url) { 'https://diggit.com/api/projects/owner/repo' }

  let(:config) { { requires: [:admin, :pull] } }
  let(:gh_client) { instance_double(Octokit::Client) }
  let(:gh_repo) { { permissions: { admin: true, pull: true, push: false } } }

  before { allow(gh_client).to receive(:repo).with('owner/repo').and_return(gh_repo) }

  context 'when user has required permissions for repo' do
    it { is_expected.to call_next_middleware }
    it { is_expected.to provide(:gh_repo, instance_of(Diggit::Github::Repo)) }
    it { is_expected.to provide(:gh_repo_path, instance_of('owner/repo')) }
  end

  context 'when user lacks a required permission' do
    before { gh_repo[:permissions][config[:requires].first] = false }

    it 'raises NotAuthorized' do
      expect { instance.call }.
        to raise_exception(Diggit::Middleware::Authorize::NotAuthorized)
    end
  end
end
