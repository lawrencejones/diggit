require 'diggit'

RSpec.describe(Diggit::Application) do
  subject(:app) { described_class.new(host: host, github_token: github_token) }

  let(:host) { "http://#{endpoint}" }
  let(:endpoint) { 'diggit.herokuapp.com' }
  let(:github_token) { 'gh-token' }

  describe '#rack_app' do
    subject(:rack_app) { app.rack_app }

    context 'with any unrecognised path' do
      let(:request) { Rack::MockRequest.env_for("#{host}/unrecognised/path") }

      it 'responds with index.html' do
        status, _, body = rack_app.call(request)

        expect(status).to be(200)
        expect(File.basename(body.path)).to eql('index.html')
      end
    end

    context 'on subdomain api' do
      let(:endpoint) { 'api.diggit.herokuapp.com' }

      it 'responds to health check' do
        request = Rack::MockRequest.env_for("#{host}/ping")
        expect(-> { rack_app.call(request) }).to respond_with_body_that_matches(/pong!/)
      end
    end
  end
end
