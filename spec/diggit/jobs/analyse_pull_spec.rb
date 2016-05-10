require 'rugged'
require 'diggit/jobs/analyse_pull'

RSpec.describe(Diggit::Jobs::AnalysePull) do
  subject(:job) { described_class.new({}) }
  let(:run!) { job.run(project.gh_path, pull, head, base) }

  let(:project) { FactoryGirl.create(:project, :diggit) }
  let(:pull) { 43 }
  let(:head) { 'head-sha' }
  let(:base) { 'base-sha' }

  let(:repo_handle) { instance_double(Rugged::Repository) }
  let(:comments) { [] }

  let(:pipeline) { instance_double(Diggit::Analysis::Pipeline) }
  let(:cloner) { instance_double(Diggit::Services::ProjectCloner) }

  before do
    allow(Diggit::Analysis::Pipeline).to receive(:new).and_return(pipeline)
    allow(Diggit::Services::ProjectCloner).to receive(:new).and_return(cloner)
    allow(Diggit::Jobs::PushAnalysisComments).to receive(:enqueue)

    allow(cloner).to receive(:clone).and_yield(repo_handle)
    allow(pipeline).to receive(:aggregate_comments).and_return(comments)
  end

  describe '.run' do
    it 'clones repo with ProjectCloner' do
      expect(Diggit::Services::ProjectCloner).
        to receive(:new).
        with(project)
      expect(cloner).to receive(:clone)
      run!
    end

    context 'when PullAnalysis exists for this pull/head/base' do
      let!(:pull_analysis) do
        FactoryGirl.create(:pull_analysis,
                           project: project, pull: pull, head: head, base: base)
      end

      it 'does not run pipeline' do
        expect(cloner).not_to receive(:clone)
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

      it 'enqueues PushAnalysisComments job' do
        expect(Diggit::Jobs::PushAnalysisComments).
          to receive(:enqueue) do |pull_analysis_id|
            expect(PullAnalysis.last.id).to equal(pull_analysis_id)
          end
        run!
      end

      context 'on a silent repo' do
        let(:project) { FactoryGirl.create(:project, :diggit, silent: true) }

        it 'does not enqueue PushAnalysisComments' do
          expect(Diggit::Jobs::PushAnalysisComments).not_to receive(:enqueue)
          run!
        end
      end
    end
  end
end
