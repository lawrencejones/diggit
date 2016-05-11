require 'diggit/services/secure'

RSpec.describe(Diggit::Services::Secure) do
  before { described_class.secret = 'secret' }
  let(:data) { 'my-super-secret-data' }

  it 'decode(encode(data)) == data' do
    encrypted, iv = described_class.encode(data)
    expect(described_class.decode(encrypted, iv)).to eql(data)
  end

  describe 'ActiveRecordHelpers' do
    class DummyModel
      attr_accessor :encrypted_token, :token_iv
      extend Diggit::Services::Secure::ActiveRecordHelpers
      encrypted_field :token, iv: :token_iv
    end
    subject(:model) { DummyModel.new }

    describe '.encrypted_field' do
      it 'sets both ciphertext and iv on set' do
        expect(model.encrypted_token).to be_nil
        expect(model.token_iv).to be_nil

        model.token = 'hello'
        expect(model.encrypted_token).not_to be_nil
        expect(model.token_iv).not_to be_nil
      end

      it 'returns decoded values on get' do
        model.token = 'hello'
        expect(model.token).to eql('hello')
      end
    end
  end
end
