require 'git'
require 'diggit/jobs/analyse_project'

RSpec.describe(Diggit::Jobs::AnalyseProject) do
  subject(:job) { described_class.new({}) }
  let(:run!) { job.run(project.id, head: head, base: base) }

  let(:project) { FactoryGirl.create(:project, :diggit) }
  let(:head) { 'head-sha' }
  let(:base) { 'base-sha' }

  let(:repo_handle) { instance_double(Git::Base) }

  before { allow(job).to receive(:clone_with_keyfile).and_return(repo_handle) }

  describe '.clone' do
    it 'yields repo handle' do
      job.clone(project) { |repo| expect(repo).to be(repo_handle) }
    end
  end

  describe '.with_temporary_keyfile' do
    it 'writes key contents to file' do
      job.with_temporary_keyfile('key-content') do |keyfile|
        expect(File.read(keyfile)).to eql('key-content')
      end
    end

    it 'deletes file after use' do
      keyfile = job.with_temporary_keyfile('key-content') { |kf| kf }
      expect(File.exist?(keyfile)).to be(false)
    end
  end
end
