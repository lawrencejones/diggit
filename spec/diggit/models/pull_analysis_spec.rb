require 'diggit/models/pull_analysis'

RSpec.describe(PullAnalysis) do
  subject(:pull_analysis) { FactoryGirl.build(:pull_analysis, project: project) }
  let(:project) { FactoryGirl.create(:project) }

  describe 'validations' do
    its(:save) { is_expected.to be(true) }

    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:pull) }
    it { is_expected.to validate_presence_of(:head) }
    it { is_expected.to validate_presence_of(:base) }
    it { is_expected.to validate_presence_of(:duration) }
    it do
      is_expected.to validate_uniqueness_of(:pull).scoped_to(:project_id, :base, :head)
    end

    it { is_expected.to belong_to(:project) }
  end

  describe 'scopes' do
    let!(:other_project) { FactoryGirl.create(:project) }
    let!(:analysis_a) do
      FactoryGirl.create(:pull_analysis,
                         project: project,
                         pull: 1, head: '1',
                         comments: []) # no comments
    end
    let!(:analysis_b) do
      FactoryGirl.create(:pull_analysis, project: project, pull: 1, head: '2')
    end
    let!(:analysis_c) { FactoryGirl.create(:pull_analysis, project: project, pull: 2) }
    let!(:analysis_d) { FactoryGirl.create(:pull_analysis, project: other_project) }

    describe '.for_project' do
      it 'finds all PullAnalyses for project with gh_path', :aggregate_failures do
        pull_analyses = described_class.for_project(project.gh_path).to_a
        expect(pull_analyses).to include(analysis_a, analysis_b, analysis_c)
        expect(pull_analyses).not_to include(analysis_d)
      end
    end

    describe '.for_pull' do
      it 'finds all PullAnalyses for that pull', :aggregate_failures do
        pull_analyses = described_class.for_project(project.gh_path).for_pull(1).to_a
        expect(pull_analyses).to include(analysis_a, analysis_b)
        expect(pull_analyses).not_to include(analysis_c)
      end
    end

    describe '.with_comments' do
      subject { described_class.with_comments.to_a }

      it { is_expected.not_to include(analysis_a) }
      it { is_expected.to include(analysis_b, analysis_c, analysis_d) }
    end
  end
end
