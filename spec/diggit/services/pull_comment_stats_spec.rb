require 'diggit/services/pull_comment_stats'

RSpec.describe(Diggit::Services::PullCommentStats) do
  subject(:stats) { described_class.new(project, pull) }

  def pull_analysis_with_comments(comments)
    FactoryGirl.create(:pull_analysis,
                       pull: pull,
                       project: project,
                       comments: comments)
  end

  let(:project) { FactoryGirl.create(:project) }
  let(:pull) { 1 }

  let!(:analysis_a) do
    pull_analysis_with_comments([
                                  { 'report' => 'A', 'index': '1' },
                                  { 'report' => 'B', 'index': '2' },
                                ])
  end
  let!(:analysis_b) do
    pull_analysis_with_comments([
                                  { 'report' => 'A', 'index': '1' },
                                  { 'report' => 'A', 'index': '3' },
                                  { 'report' => 'B', 'index': '2' },
                                ])
  end
  let!(:analysis_c) do
    pull_analysis_with_comments([{ 'report' => 'A', 'index': '1' }])
  end

  describe '.comments' do
    subject(:comments) { stats.comments }

    it 'includes all unique comments' do
      expect(comments).to include('report' => 'A', 'index' => '1')
      expect(comments).to include('report' => 'A', 'index' => '3')
      expect(comments).to include('report' => 'B', 'index' => '2')
      expect(comments.size).to be(3)
    end
  end

  describe '.unresolved' do
    subject(:unresolved) { stats.unresolved }

    it 'includes all comments from last analysis' do
      expect(unresolved).to eql(['report' => 'A', 'index' => '1'])
    end
  end

  describe '.resolved' do
    subject(:resolved) { stats.resolved }

    it { is_expected.to include('report' => 'A', 'index' => '3') }
    it { is_expected.to include('report' => 'B', 'index' => '2') }
  end
end
