require 'git'
require 'diggit/jobs/analyse_pull'

RSpec.describe(Diggit::Jobs::AnalysePull) do
  subject(:job) { described_class.new({}) }
  let(:run!) { job.run(project.gh_path, pull, head, base) }

  let(:project) { FactoryGirl.create(:project, :diggit) }
  let(:pull) { 43 }
  let(:head) { 'head-sha' }
  let(:base) { 'base-sha' }

  let(:repo_handle) { instance_double(Git::Base) }
  let(:comments) { [] }

  let(:pipeline) { instance_double(Diggit::Analysis::Pipeline) }
  let(:cloner) { instance_double(Diggit::Github::Cloner) }

  before do
    allow(Diggit::Analysis::Pipeline).to receive(:new).and_return(pipeline)
    allow(Diggit::Github::Cloner).to receive(:new).and_return(cloner)
    allow(Diggit::Jobs::PushAnalysisComments).to receive(:enqueue)

    allow(cloner).to receive(:clone).and_yield(repo_handle)
    allow(cloner).to receive(:clone_with_key).and_yield(repo_handle)
    allow(pipeline).to receive(:aggregate_comments).and_return(comments)
  end

  describe '.run' do
    context 'when project lacks deploy keys' do
      it 'calls simple clone' do
        expect(cloner).to receive(:clone)
        run!
      end
    end

    context 'when a project has deploy keys' do
      let(:project) { FactoryGirl.create(:project, :diggit, :deploy_keys) }

      it 'clones with key' do
        expect(cloner).to receive(:clone_with_key).with(project.ssh_private_key)
        run!
      end
    end

    context 'when PullAnalysis exists for this pull/head/base' do
      let!(:pull_analysis) do
        FactoryGirl.create(:pull_analysis,
                           project: project, pull: pull, head: head, base: base)
      end

      it 'does not run pipeline' do
        expect(job).not_to receive(:clone)
        expect(Diggit::Analysis::Pipeline).not_to receive(:new)
        expect(Diggit::Jobs::PushAnalysisComments).not_to receive(:enqueue)
        run!
      end
    end

    context 'when referenced commits are no longer in repo' do
      before do
        allow(Diggit::Analysis::Pipeline).
          to receive(:new).
          and_raise(Diggit::Analysis::Pipeline::BadGitHistory)
      end

      it 'does not create analysis' do
        expect { run! }.not_to change(PullAnalysis, :count)
      end
    end

    context 'with valid pull' do
      it 'creates new PullAnalysis' do
        expect { run! }.to change(PullAnalysis, :count).by(1)
        pull_analysis = PullAnalysis.last

        expect(pull_analysis.pull).to eql(pull)
        expect(pull_analysis.project_id).to eql(project.id)
        expect(pull_analysis.comments).to match(comments.as_json)
      end
    end
  end
end
