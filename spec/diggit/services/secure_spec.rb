require 'diggit/services/secure'

RSpec.describe(Diggit::Services::Secure) do
  before { described_class.secret = 'secret' }
  let(:data) { 'my-super-secret-data' }

  it 'decode(encode(data)) == data' do
    encrypted, iv = described_class.encode(data)
    expect(described_class.decode(encrypted, iv)).to eql(data)
  end
end
