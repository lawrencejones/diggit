require 'diggit/middleware/authorize'

RSpec.describe(Diggit::Middleware::Authorize) do
  subject(:instance) { described_class.new(context, null_middleware, {}) }

  let(:context) { { request: request } }
  let(:request) { mock_request_for(url, 'HTTP_AUTHORIZATION' => auth_header) }
  let(:url) { 'https://diggit.com/api/a/protected/path' }
  let(:auth_header) { "Bearer #{auth_token}" }

  let(:token_expiry) { Time.now.advance(minutes: 10) }

  let(:auth_token) { Diggit::Services::Jwt.encode(auth_token_data, token_expiry) }
  let(:auth_token_data) { load_json_fixture('models/auth_token_data.fixture.json') }

  context 'with valid auth token' do
    it { is_expected.to call_next_middleware }
    it { is_expected.to provide(:gh_token, auth_token_data['gh_token']) }
  end

  context 'with missing header' do
    let(:auth_header) { nil }

    it { is_expected.to respond_with_status(401) }
    it { is_expected.to respond_with_body_that_matches(/missing_authorization_header/) }
  end

  context 'with malformed header' do
    let(:auth_header) { 'NotBearer token' }

    it { is_expected.to respond_with_status(401) }
    it { is_expected.to respond_with_body_that_matches(/malformed_authorization_header/) }
  end

  context 'with expired header' do
    let(:token_expiry) { Time.now.advance(minutes: -10) }

    it { is_expected.to respond_with_status(401) }
    it { is_expected.to respond_with_body_that_matches(/expired_authorization_header/) }
  end
end
