require 'nokogiri'
require 'diggit/jobs/daily_analysis_summary'

RSpec.describe(Diggit::Jobs::DailyAnalysisSummary) do
  subject(:job) { described_class.new({}) }
  before { allow(job).to receive(:start_at).and_return(Time.zone.now.advance(hours: 6)) }

  def mock_comment(index, report)
    { report: report, index: index }.stringify_keys
  end

  let(:comment_1) { mock_comment('file.rb:method', 'RefactorDiligence') }
  let(:comment_2) { mock_comment('another_file.rb:method', 'RefactorDiligence') }
  let(:comment_3) { mock_comment('another_nutha_file.rb', 'Complexity') }

  describe '.render' do
    subject(:html) { job.send(:render) }
    let(:dom) { Nokogiri.parse(html) }

    let!(:project) { FactoryGirl.create(:project) }
    let!(:project_old) { FactoryGirl.create(:project) }

    let!(:analysis_a) do
      FactoryGirl.create(:pull_analysis,
                         project: project,
                         comments: [comment_1],
                         duration: 5.0)
    end
    let!(:analysis_b) do
      FactoryGirl.create(:pull_analysis,
                         project: project,
                         comments: [comment_2, comment_3],
                         duration: 3.0)
    end
    let!(:old_analysis) do
      FactoryGirl.create(:pull_analysis,
                         project: project_old,
                         created_at: Time.zone.now.advance(days: -1),
                         duration: 99.0)
    end

    let(:project_links) { dom.css('a.project') }

    it 'renders projects that have pull analyses in the time range' do
      expect(project_links.map(&:content).map(&:strip)).to eql([project.gh_path])
    end

    describe '<p class="summary">' do
      subject(:summary) { dom.css('p.summary').first }

      it { is_expected.to match(/2 new Pull Analyses/) }
      it { is_expected.to match(/3 new comments/) }
    end

    describe '<p class="duration-stats">' do
      subject(:duration_stats) { dom.css('p.duration-stats').first.text.gsub(/\s+/, ' ') }

      it { is_expected.to match(/Each pull took 4s on average/) }
      it { is_expected.to match(/longest analysis took 5s/) }
      it { is_expected.to match(/slowest 10% of analyses averaged 5s/) }
    end

    describe '<p class="report-stats">' do
      subject(:report_stats) { dom.css('p.report-stats').first.text.gsub(/\s+/, ' ') }

      it { is_expected.to match(/2 were RefactorDiligence/) }
      it { is_expected.to match(/1 were Complexity/) }
    end
  end
end
