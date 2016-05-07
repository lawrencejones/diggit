require 'diggit/services/project_cloner'

RSpec.describe(Diggit::Services::ProjectCloner) do
  subject(:cloner) { described_class.new(project) }
  let(:project) { FactoryGirl.build_stubbed(:project, :diggit, :deploy_keys) }

  let(:test_cache_dir) { Dir.mktmpdir('project-cloner-specs') }
  before { stub_const("#{described_class}::CACHE_DIR", test_cache_dir) }
  after { FileUtils.rm_rf(test_cache_dir) }

  let(:repo_cache_dir) { File.join(test_cache_dir, project.gh_path) }

  describe '.clone' do
    before { allow_any_instance_of(Git::Base).to receive(:fetch) }

    it 'adds remote to bare repo' do
      expect_any_instance_of(Git::Base).
        to receive(:add_remote).
        with('lawrencejones/diggit', 'git@github.com:lawrencejones/diggit')
      cloner.clone { |repo| repo }
    end

    it 'fetches from remote into cached repo' do
      expect_any_instance_of(Git::Base).
        to receive(:fetch).
        with('lawrencejones/diggit')
      cloner.clone { |repo| repo }
    end

    it 'fetches with git ssh environment' do
      expect_any_instance_of(Git::Base).to receive(:fetch) do |_repo|
        keyfile = ENV.fetch('GIT_SSH_COMMAND').match(/^ssh -i (\S+)$/)[1]
        expect(File.read(keyfile)).to eql(project.ssh_private_key)
      end
      cloner.clone { |repo| repo }
    end

    it 'yields with instance of Git::Base' do
      expect { |b| cloner.clone(&b) }.to yield_with_args(instance_of(Git::Base))
    end

    it 'creates bare repo at cache location' do
      cloner.clone { |repo| repo }
      expect(File.directory?(File.join(repo_cache_dir, '.git'))).to be(true)
    end
  end

  # private

  describe '.with_temporary_keyfile' do
    it 'writes key contents to file' do
      cloner.send(:with_temporary_keyfile) do |keyfile|
        expect(File.read(keyfile)).to eql(project.ssh_private_key)
      end
    end

    it 'deletes file after use' do
      keyfile = cloner.send(:with_temporary_keyfile) { |kf| kf }
      expect(File.exist?(keyfile)).to be(false)
    end
  end
end
