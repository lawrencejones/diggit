require 'diggit/middleware/github_client'

RSpec.describe(Diggit::Middleware::GithubClient) do
  subject(:instance) { described_class.new(context, next_middleware, {}) }
  let(:context) { { gh_token: 'gh-token' } }
  let(:next_middleware) { null_middleware }

  it { is_expected.to call_next_middleware }
  it { is_expected.to provide(gh_client: instance_of(Octokit::Client)) }

  it 'initializes Ocktokit::Client with gh_token' do
    expect(Octokit::Client).
      to receive(:new).
      with(hash_including(access_token: 'gh-token'))
    instance.call
  end

  context 'when Octokit raises Unauthorized' do
    before { allow(next_middleware).to receive(:call).and_raise(Octokit::Unauthorized) }

    it { is_expected.to respond_with_status(401) }
    it { is_expected.to respond_with_body_that_matches(/bad_github_auth/) }
  end
end
