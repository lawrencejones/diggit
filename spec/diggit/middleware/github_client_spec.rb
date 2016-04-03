require 'diggit/middleware/github_client'

RSpec.describe(Diggit::Middleware::GithubClient) do
  subject(:instance) { described_class.new(context, null_middleware, {}) }
  let(:context) { { gh_token: 'gh-token' } }

  it { is_expected.to call_next_middleware }
  it { is_expected.to provide(gh_client: instance_of(Octokit::Client)) }

  it 'initializes Ocktokit::Client with gh_token' do
    expect(Octokit::Client).
      to receive(:new).
      with(hash_including(access_token: 'gh-token'))
    instance.call
  end
end
