require 'nokogiri'
require 'diggit/jobs/daily_analysis_summary'

RSpec.describe(Diggit::Jobs::DailyAnalysisSummary) do
  subject(:job) { described_class.new({}) }

  before { allow(job).to receive(:start_at).and_return(Time.zone.now.advance(hours: 6)) }

  describe '.render' do
    subject(:html) { job.send(:render) }
    let(:dom) { Nokogiri.parse(html) }

    let!(:project) { FactoryGirl.create(:project) }
    let!(:project_old) { FactoryGirl.create(:project) }

    let!(:analysis_a) do
      FactoryGirl.create(:pull_analysis, project: project, comments: [1])
    end
    let!(:analysis_b) do
      FactoryGirl.create(:pull_analysis, project: project, comments: [2, 3])
    end
    let!(:old_analysis) do
      FactoryGirl.create(:pull_analysis, project: project_old,
                                         created_at: Time.zone.now.advance(days: -1))
    end

    let(:project_links) { dom.css('a.project') }
    let(:summary) { dom.css('p.summary').first }

    it 'correctly states totals in summary paragraph' do
      expect(summary.content).to match(/2 new Pull Analyses/)
      expect(summary.content).to match(/3 new comments/)
    end

    it 'renders projects that have pull analyses in the time range' do
      expect(project_links.map(&:content).map(&:strip)).to eql([project.gh_path])
    end
  end
end
