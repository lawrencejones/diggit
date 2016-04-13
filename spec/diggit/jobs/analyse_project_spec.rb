require 'git'
require 'diggit/jobs/analyse_project'

RSpec.describe(Diggit::Jobs::AnalyseProject) do
  subject(:job) { described_class.new({}) }
  let(:run!) { job.run(project.id, pull, head: head, base: base) }

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
    context 'with line-based comments' do
      let(:comments) { [{ message: 'This line is terrible!', location: 'file.rb:9' }] }

      it 'applies them with CommentGenerator' do
        expect(comment_generator).
          to receive(:add_comment_on_file).
          with('This line is terrible!', 'file.rb', 9)
        expect(comment_generator).to receive(:send)
        run!
      end
    end

    context 'with non-line-based comments' do
      let(:comments) { [{ message: 'Awful PR' }] }

      it 'applies them with CommentGenerator' do
        expect(comment_generator).
          to receive(:add_comment).
          with('Awful PR')
        expect(comment_generator).to receive(:send)
        run!
      end
    end
  end
end
