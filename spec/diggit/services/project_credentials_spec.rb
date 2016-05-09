require 'diggit/services/project_credentials'

RSpec.describe(Diggit::Services::ProjectCredentials) do
  subject(:credentials) { described_class.new(project) }

  before { stub_const("#{described_class}::DEFAULT_KEYFILES", default_keyfiles) }
  let(:default_keyfiles) { { privatekey: 'id_rsa', publickey: 'id_rsa.pub' } }

  describe '.with_keyfiles' do
    context 'when project has no deploy keys' do
      let(:project) { FactoryGirl.build_stubbed(:project) }

      it 'yields with default_keyfiles' do
        expect { |b| credentials.with_keyfiles(&b) }.to yield_with_args(default_keyfiles)
      end
    end

    context 'when project has deploy keys' do
      let(:project) { FactoryGirl.build_stubbed(:project, :deploy_keys) }

      it 'yields with paths to deploy key contents' do
        credentials.with_keyfiles do |privatekey:, publickey:|
          expect(File.read(privatekey)).to eql(project.ssh_private_key)
          expect(File.read(publickey)).to eql(project.ssh_public_key)
        end
      end

      it 'destroys credentials after use' do
        files = credentials.with_keyfiles(&:values)
        files.each { |file| expect(File.exist?(file)).to be(false) }
      end
    end
  end
end
