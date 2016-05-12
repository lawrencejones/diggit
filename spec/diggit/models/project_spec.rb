require 'diggit/models/project'

RSpec.describe(Project) do
  subject(:repo) { described_class.new(params) }
  let(:params) do
    { gh_path: 'lawrencejones/diggit', watch: false,
      ssh_public_key: 'ssh-public-key', ssh_private_key: 'ssh-private-key' }
  end

  it { is_expected.to be_valid }
  it { is_expected.to validate_presence_of(:gh_path) }
  it { is_expected.not_to allow_value('lawrencejones').for(:gh_path) }

  context 'with unspecified watch' do
    before { params.delete(:watch) }
    its(:watch) { is_expected.to be(true) }
  end

  context 'with only one ssh key set' do
    before { params[:ssh_public_key] = nil }
    it { is_expected.not_to be_valid }
  end

  describe '.ssh_private_key' do
    it 'encrypts into .encrypted_ssh_private_key and .iv when set' do
      repo.ssh_private_key = 'ssh-private-key'
      expect(repo.encrypted_ssh_private_key).not_to be_nil
      expect(repo.ssh_initialization_vector).not_to be_nil
    end

    it 'decodes the encrypted field when accessed' do
      expect(repo.ssh_private_key).to eql('ssh-private-key')
    end
  end

  describe '.generate_keypair!' do
    it 'saves the model' do
      expect { repo.generate_keypair! }.to change(Project, :count).by(1)
    end

    it 'sets public/private key and initialization vector', :aggregate_failures do
      repo.generate_keypair!

      expect(repo.ssh_public_key).not_to be_nil
      expect(repo.encrypted_ssh_private_key).not_to be_nil
      expect(repo.ssh_initialization_vector).not_to be_nil
    end
  end
end
