require 'active_support/core_ext/hash'
require 'diggit/middleware/json_schema_validation'

RSpec.describe(Diggit::Middleware::JsonSchemaValidation) do
  subject(:instance) { described_class.new(context, null_middleware, config) }
  let(:config) { { schema: schema } }

  let(:context) do
    { request: mock_request_for('https://diggit.com/api/projects',
                                method: 'POST', params: params) }
  end

  let(:valid_params) { { 'required_key' => 7, 'optional_string' => 'optional' } }
  let(:schema) do
    { type: :object,
      required: ['required_key'],
      properties: {
        required_key: { type: 'integer' },
        optional_string: { type: 'string' },
      },
    }
  end

  context 'with valid body' do
    let(:params) { valid_params }
    it { is_expected.to call_next_middleware }
  end

  context 'with missing required key' do
    let(:params) { valid_params.except('required_key') }

    it { is_expected.to respond_with_status(400) }
    it { is_expected.to respond_with_body_that_matches(/did not contain.*required_key/) }
  end
end
