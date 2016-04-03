require 'diggit/routes/auth'
require 'diggit/services/jwt'

RSpec.describe(Diggit::Routes::Auth) do
  subject(:instance) { described_class.new(context, null_middleware, config) }

  let(:context) { { request: mock_request_for(url, params: params, method: method) } }
  let(:params) { nil }
  let(:config) do
    { client_id: 'client_id', scope: 'scope', secret: 'secret' }
  end

  describe(described_class::CreateAccessToken) do
    let(:url) { 'https://diggit.com/api/auth/access_token' }
    let(:method) { 'POST' }
    let(:params) do
      { 'state' => 'valid_state', 'code' => 'github_access_code' }
    end

    before do
      allow(Diggit::Services::Jwt).
        to receive(:decode).
        with(anything) do |state|
          fail(JWT::ExpiredSignature) if state == 'expired_state'
          { 'data' => state == 'valid_state' ? 'github' : state }
        end
      allow(Diggit::Services::Jwt).
        to receive(:encode).
        with(anything, anything) { |payload| payload }
    end

    context 'with valid state and successful github exchange' do
      before do
        allow(instance).
          to receive(:access_token_from_github).
          and_return('github_token')
      end

      let(:json_body) { JSON.parse(instance.call[2][0]) }

      it { is_expected.to respond_with_status(200) }
      it 'returns jwt token that encodes the github token' do
        # Encode has been mocked as an identity
        decoded_token_data = json_body['access_token']['token']
        expect(decoded_token_data['gh_token']).to eql('github_token')
      end
    end

    context 'with invalid state' do
      before { params['state'] = 'expired_state' }

      it { is_expected.to respond_with_status(401) }
      it { is_expected.to respond_with_body_that_matches(/invalid_state/) }
    end

    context 'with bad github access token exchange' do
      before do
        allow(instance).
          to receive(:access_token_from_github).
          and_return(nil, 'my_error_message')
      end

      it { is_expected.to respond_with_status(401) }
      it { is_expected.to respond_with_body_that_matches(/bad_oauth_exchange/) }
    end
  end

  describe(described_class::Redirect) do
    let(:url) { 'https://diggit.com/api/auth/redirect' }
    let(:method) { 'GET' }

    let(:github_authorize) { Diggit::Routes::Auth::GITHUB_AUTHORIZE }
    let(:state_expiration) { Diggit::Routes::Auth::STATE_EXPIRATION }

    let(:redirect_location) { instance.call[1].fetch('Location') }
    let(:query_params) { Hash[URI.parse(redirect_location).query.scan(/(\w+)=([^&]+)/)] }

    it { is_expected.to respond_with_status(302) }
    it { is_expected.to respond_with_header('Location', github_authorize) }

    it 'encodes query with all params' do
      expect(query_params.keys).to include('client_id', 'scope', 'state')
    end

    it 'encodes state param that expires STATE_EXPIRATION minutes later' do
      state = query_params.fetch('state')
      expect { Diggit::Services::Jwt.decode(state) }.not_to raise_error
      Timecop.travel(Time.now.advance(minutes: state_expiration + 1)) do
        expect { Diggit::Services::Jwt.decode(state) }.
          to raise_error(JWT::ExpiredSignature)
      end
    end
  end
end
