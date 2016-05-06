require 'diggit/jobs/push_analysis_comments'

RSpec.describe(Diggit::Jobs::PushAnalysisComments) do
  subject(:job) { described_class.new({}) }
  let(:run!) { job.run(pull_analysis.id) }

  let(:head) { 'head-sha' }
  let(:base) { 'base-sha' }
  let(:pushed_to_github) { false }

  let!(:pull_analysis) do
    FactoryGirl.create(:pull_analysis,
                       pushed_to_github: pushed_to_github, comments: comments,
                       base: base, head: head)
  end
  let(:comments) do
    [{ report: 'Complexity',
       index: 'file.rb',
       message: 'increased in complexity by 50% over last 7 days',
       location: 'file.rb:1' },
     { report: 'RefactorDiligence',
       index: 'Socket::initialize',
       message: 'Socket::initialize has increase in size the last 3 times',
       location: 'socket.rb:20' }]
  end

  let(:comment_generator) { instance_double(Diggit::Github::CommentGenerator) }
  let(:gh_client) { instance_double(Octokit::Client) }

  before do
    allow(Diggit::Github).to receive(:client).and_return(gh_client)
    allow(Diggit::Github::CommentGenerator).to receive(:new).and_return(comment_generator)

    allow(comment_generator).to receive(:add_comment)
    allow(comment_generator).to receive(:push)
    expect(job).to receive(:destroy)
  end

  shared_examples 'audited comment job' do
    it 'sets pushed_to_github=true' do
      expect { run! }.
        to change { pull_analysis.reload.pushed_to_github }.
        from(false).to(true)
    end
  end

  context 'when analysis has already been pushed_to_github' do
    let(:pushed_to_github) { true }

    it 'does nothing' do
      expect(comment_generator).not_to receive(:push)
      run!
    end
  end

  context 'when there are no existing analyses for this pull' do
    it_behaves_like 'audited comment job'

    it 'sends all comments to github' do
      expect(comment_generator).
        to receive(:add_comment).
        with('increased in complexity by 50% over last 7 days', 'file.rb:1')
      expect(comment_generator).
        to receive(:add_comment).
        with('Socket::initialize has increase in size the last 3 times', 'socket.rb:20')
      expect(comment_generator).to receive(:push)
      run!
    end
  end

  context 'when analyses exist for this pull' do
    let!(:existing_pull_analysis) do
      FactoryGirl.create(:pull_analysis,
                         comments: existing_comments, base: base, head: 'old-head-sha')
    end
    let(:existing_comments) do
      [{ report: 'RefactorDiligence',
         index: 'Socket::initialize',
         message: 'Socket::initialize has increase in size the last 3 times',
         location: 'socket.rb:15' }]
    end

    it_behaves_like 'audited comment job'

    it 'sends new comments to github' do
      expect(comment_generator).
        to receive(:add_comment).
        with('increased in complexity by 50% over last 7 days', 'file.rb:1')
      expect(comment_generator).to receive(:push)
      run!
    end

    it 'does not send existing comments to github' do
      expect(comment_generator).
        not_to receive(:add_comment).
        with('Socket::initialize has increase in size the last 3 times', 'socket.rb:15')
      expect(comment_generator).to receive(:push)
      run!
    end
  end
end
