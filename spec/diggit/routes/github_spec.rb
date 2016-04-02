require 'diggit/routes/github'

RSpec.describe(Diggit::Routes::Github) do
  describe '.state_create' do
    it 'produces string token' do
      expect(described_class.state_create('secret')).
        to be_a(String)
    end
  end

  describe '.state_verify' do
    subject { described_class.state_verify(token, 'secret') }

    context 'with valid token' do
      let(:token) { described_class.state_create('secret') }
      it { is_expected.to be(true) }
    end

    context 'with invalid token' do
      let(:token) { 'invalid-token' }
      it { is_expected.to be(false) }
    end

    context 'with expired token' do
      let(:token) do
        Timecop.travel(Time.now.advance(minutes: -15)) do
          described_class.state_create('secret')
        end
      end

      it { is_expected.to be(false) }
    end
  end
end

RSpec.describe(Diggit::Routes::Github::Redirect) do
  subject(:instance) { described_class.new(context, null_middleware, config) }

  let(:context) { { request: mock_request_for(url) } }
  let(:url) { 'https://diggit.com/api/github/redirect' }
  let(:github_authorize) { Diggit::Routes::Github::GITHUB_AUTHORIZE }
  let(:config) do
    { client_id: 'client_id', scope: 'scope',
      redirect_uri: 'redirect_uri', secret: 'secret' }
  end

  let(:redirect_location) { instance.call[1].fetch('Location') }

  it { is_expected.to respond_with_status(302) }
  it { is_expected.to respond_with_header('Location', github_authorize) }

  it 'encodes query with all params' do
    query_params = URI.parse(redirect_location).query.scan(/(\w+)=/).flatten
    expect(query_params).to include('client_id', 'scope', 'redirect_uri', 'state')
  end
end
