require 'git'
require 'diggit/jobs/analyse_project'

RSpec.describe(Diggit::Jobs::AnalyseProject) do
  subject(:job) { described_class.new({}) }
  let(:run!) { job.run(project.id, pull, head, base) }

  let(:project) { FactoryGirl.create(:project, :diggit) }
  let(:pull) { 43 }
  let(:head) { 'head-sha' }
  let(:base) { 'base-sha' }

  let(:repo_handle) { instance_double(Git::Base) }
  let(:comments) { [] }

  let(:gh_client) { instance_double(Octokit::Client) }
  let(:comment_generator) { instance_double(Diggit::Github::CommentGenerator) }
  let(:pipeline) { instance_double(Diggit::Analysis::Pipeline) }
  let(:cloner) { instance_double(Diggit::Github::Cloner) }

  before do
    allow(Diggit::Github).to receive(:client).and_return(gh_client)
    allow(Diggit::Github::CommentGenerator).to receive(:new).and_return(comment_generator)
    allow(Diggit::Analysis::Pipeline).to receive(:new).and_return(pipeline)
    allow(Diggit::Github::Cloner).to receive(:new).and_return(cloner)

    allow(cloner).to receive(:clone).and_yield(repo_handle)
    allow(pipeline).to receive(:aggregate_comments).and_return(comments)
  end

  describe '.run' do
    context 'when PullAnalysis exists for this pull' do
      let!(:pull_analysis) do
        FactoryGirl.create(:pull_analysis, project: project, pull: pull)
      end

      it 'does not run pipeline' do
        expect(job).not_to receive(:clone)
        expect(Diggit::Analysis::Pipeline).not_to receive(:new)
        expect(comment_generator).not_to receive(:push)
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

    shared_examples 'audited analysis' do
      before { comment_generator.as_null_object }

      it 'creates new PullAnalysis' do
        expect { run! }.to change(PullAnalysis, :count).by(1)
        pull_analysis = PullAnalysis.last

        expect(pull_analysis.pull).to eql(pull)
        expect(pull_analysis.project_id).to eql(project.id)
        expect(pull_analysis.comments).to match(comments.as_json)
      end
    end

    context 'with line-based comments' do
      let(:comments) { [{ message: 'This line is terrible!', location: 'file.rb:9' }] }

      it_behaves_like 'audited analysis'

      it 'applies them with CommentGenerator' do
        expect(comment_generator).
          to receive(:add_comment).
          with('This line is terrible!', 'file.rb:9')
        expect(comment_generator).to receive(:push)
        expect(job).to receive(:destroy)
        run!
      end
    end

    context 'with non-line-based comments' do
      let(:comments) { [{ message: 'Awful PR' }] }

      it_behaves_like 'audited analysis'

      it 'applies them with CommentGenerator' do
        expect(comment_generator).
          to receive(:add_comment).
          with('Awful PR', nil)
        expect(comment_generator).to receive(:push)
        expect(job).to receive(:destroy)
        run!
      end
    end
  end
end
