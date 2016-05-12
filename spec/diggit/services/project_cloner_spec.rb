require 'diggit/services/project_cloner'

RSpec.describe(Diggit::Services::ProjectCloner) do
  subject(:cloner) { described_class.new(project) }

  let(:project) { FactoryGirl.build_stubbed(:project, :diggit) }
  let(:project_with_keys) { FactoryGirl.build_stubbed(:project, :diggit, :deploy_keys) }

  let(:test_cache_dir) { Dir.mktmpdir('project-cloner-specs') }
  before { stub_const("#{described_class}::CACHE_DIR", test_cache_dir) }
  after { FileUtils.rm_rf(test_cache_dir) }

  let(:repo_cache_dir) { File.join(test_cache_dir, project.gh_path) }
  let(:cache_repo) { Rugged::Repository.new(repo_cache_dir) }

  describe '.new' do
    context 'when cached repo does not already exist' do
      let(:origin) { cache_repo.remotes.find { |r| r.name == 'origin' } }

      it 'creates it' do
        expect { cloner }.
          to change { File.directory?(repo_cache_dir) }.
          from(false).to(true)
      end

      it 'configures origin remote url' do
        cloner
        expect(origin.url).to eql('git@github.com:lawrencejones/diggit')
      end

      it 'configures origin fetch refspec for pulls' do
        cloner
        expect(origin.fetch_refspecs).to include(described_class::GITHUB_PULLS_REFSPEC)
      end
    end
  end

  describe '.clone' do
    before { allow_any_instance_of(Rugged::Repository).to receive(:fetch) }

    it 'fetches from origin with ssh credentials' do
      expect_any_instance_of(Rugged::Repository).
        to receive(:fetch).
        with('origin', credentials: instance_of(Rugged::Credentials::SshKey))
      cloner.clone { |repo| repo }
    end

    it 'yields with instance of Rugged::Repo' do
      expect { |b| cloner.clone(&b) }.
        to yield_with_args(instance_of(Rugged::Repository))
    end
  end

  context 'cloning from github repo', integration: true do
    let(:project) do
      FactoryGirl.create(:project, gh_path: 'lawrencejones/diggit-tests')
    end

    it 'successfully pulls diggit-tests by using default creds' do
      cloner.clone do |repo|
        @yielded = true
        expect(repo.exists?('9c6ddb63e1d90f7d4d88f210884cd73bcaeccde8')).to be(true)
      end
      expect(@yielded).to be(true)
    end
  end
end
