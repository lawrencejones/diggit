require 'diggit/services/environment'

RSpec.describe(Diggit::Services::Environment) do
  describe '.with_temporary_env' do
    before { ENV['ENV_KEY'] = 'existing_value' }
    let(:env) { { 'ENV_KEY' => 'temporary_value' } }

    it 'runs block with modified env' do
      described_class.with_temporary_env(env) do
        expect(ENV['ENV_KEY']).to eql('temporary_value')
      end
    end

    it 'restores old value' do
      described_class.with_temporary_env(env) { true }
      expect(ENV['ENV_KEY']).to eql('existing_value')
    end

    context 'with failing block' do
      it 'restores old value' do
        begin
          described_class.with_temporary_env(env) { fail 'ahh!' }
          expect(ENV['ENV_KEY']).to eql('existing_value')
        rescue RuntimeError => err
          expect(err.message).to match(/ahh!/)
        end
      end
    end
  end
end
