require 'diggit/models/pull_analysis'

RSpec.describe(PullAnalysis) do
  subject(:pull_analysis) { FactoryGirl.build(:pull_analysis, project: project) }
  let(:project) { FactoryGirl.create(:project) }

  describe 'validations' do
    its(:save) { is_expected.to be(true) }

    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:pull) }
    it { is_expected.to validate_presence_of(:comments) }
    it { is_expected.to validate_uniqueness_of(:pull).scoped_to(:project_id) }

    it { is_expected.to belong_to(:project) }
  end

  describe 'scopes' do
    describe '.for_project' do
      let(:other_project) { FactoryGirl.create(:project) }
      let(:analysis_a) { FactoryGirl.create(:pull_analysis, project: project) }
      let(:analysis_b) { FactoryGirl.create(:pull_analysis, project: project) }
      let(:analysis_c) { FactoryGirl.create(:pull_analysis, project: other_project) }

      it 'finds all PullAnalyses for project with gh_path', :aggregate_failures do
        pull_analyses = described_class.for_project(project.gh_path)
        expect(pull_analyses).to include(analysis_a, analysis_b)
        expect(pull_analyses).not_to include(analysis_c)
      end
    end
  end
end
