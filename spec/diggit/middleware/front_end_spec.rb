require 'diggit/middleware/front_end'

RSpec.describe(Diggit::Middleware::FrontEnd) do
  subject(:instance) { described_class.new(context, null_middleware, config) }

  let(:context) { { request: mock_request_for(url) } }
  let(:config) { { rack_static: rack_static, fallback_path: fallback_path } }

  let(:rack_static) { instance_double(Rack::Static) }
  let(:fallback_path) { '/index.html' }

  context 'with non-api namespaced request' do
    let(:url) { 'https://diggit.com/build.js' }

    let(:not_found_build) { [404, {}, []] }
    let(:found_build) { [200, {}, ['/build.js']] }
    let(:found_fallback) { [200, {}, [fallback_path]] }

    context 'to existing static asset' do
      before { allow(rack_static).to receive(:call).and_return(found_build) }

      it { is_expected.to respond_with_body_that_matches('/build.js') }
    end

    context 'to missing static asset' do
      before do
        allow(rack_static).
          to receive(:call).
          and_return(not_found_build, found_fallback)
      end

      it { is_expected.to respond_with_body_that_matches(fallback_path) }
    end
  end
end
