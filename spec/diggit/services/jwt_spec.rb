require 'diggit/services/jwt'

RSpec.describe(Diggit::Services::Jwt) do
  before { described_class.secret = 'secret' }
  let(:data) { { 'hello' => 'world' } }

  it 'decode(encode(data)) == data' do
    cipher = described_class.encode(data, Time.now.advance(minutes: 10))
    expect(described_class.decode(cipher)['data']).to eql(data)
  end
end
