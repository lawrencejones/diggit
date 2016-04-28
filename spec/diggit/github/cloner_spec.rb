require 'diggit/github/cloner'

RSpec.describe(Diggit::Github::Cloner) do
  subject(:cloner) { described_class.new(gh_path) }

  let(:ssh_private_key) { 'ssh-private-key' }
  let(:gh_path) { 'lawrencejones/diggit' }

  # Mock git clone to produce temporary git repo
  before do
    allow(Git).to receive(:clone) do |remote, destination|
      g = Git.init(destination)
      File.write(File.join(g.dir.path, 'remote'), remote)
      g.add('remote')
      g.commit_all('adds remote')
    end
  end

  describe '.clone' do
    it 'yields with repo' do
      cloner.clone do |repo|
        expect(repo).to be_instance_of(Git::Base)
        expect(repo.show('HEAD', 'remote')).to start_with('https://github.com/')
      end
    end
  end

  describe '.clone_with_key' do
    it 'yields with repo' do
      cloner.clone_with_key(ssh_private_key) do |repo|
        expect(repo).to be_instance_of(Git::Base)
        expect(repo.show('HEAD', 'remote')).to start_with('git@github.com:')
      end
    end
  end

  # private

  describe '.with_temporary_keyfile' do
    it 'writes key contents to file' do
      cloner.send(:with_temporary_keyfile, 'key-content') do |keyfile|
        expect(File.read(keyfile)).to eql('key-content')
      end
    end

    it 'deletes file after use' do
      keyfile = cloner.send(:with_temporary_keyfile, 'key-content') { |kf| kf }
      expect(File.exist?(keyfile)).to be(false)
    end
  end
end
