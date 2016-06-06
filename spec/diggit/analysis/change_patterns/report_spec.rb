require 'diggit/analysis/change_patterns/report'

# rubocop:disable Metrics/MethodLength
def change_patterns_test_repo
  TemporaryAnalysisRepo.create do |repo|
    repo.write('Gemfile', "gem 'sinatra'")
    repo.write('app.rb', 'Sinatra::App')
    repo.commit('initial')

    repo.write('app.rb', "require 'app_controller'; Sinatra::App")
    repo.write('app_controller.rb', 'class AppController; end')
    repo.commit('app controller')

    repo.write('app_template.html', '<html></html>')
    repo.write('app_controller.rb', <<-RUBY)
    class AppController
      def render_template
        render('app_template.html')
      end
    end
    RUBY
    repo.commit('render app_template')

    repo.write('app_template.html', '<html> @first </html>')
    repo.write('app_controller.rb', <<-RUBY)
    class AppController
      def render_template
        render('app_template.html', first: 'first')
      end
    end
    RUBY
    repo.commit('@first param for app_template render')

    repo.write('app_template.html', '<html> @first @second</html>')
    repo.write('app_controller.rb', <<-RUBY)
    class AppController
      def render_template
        render('app_template.html', first: 'first', second: 'second')
      end
    end
    RUBY
    repo.commit('@second param for app_template render')

    repo.write('app_template.html', <<-HTML)
    <html>
      <ul>
        <li>@first</li>
        <li>@second</li>
      </ul>
    </html>
    HTML
    repo.commit('Add additional formatting to app_template')

    # Create suspect feature branch
    repo.branch('feature')
    repo.write('app_template.html', '<html> @first @second @third </html>')
    repo.commit('@third param for app_template')
  end
end
# rubocop:enable Metrics/MethodLength

RSpec.describe(Diggit::Analysis::ChangePatterns::Report) do
  subject(:report) do
    described_class.new(repo, { head: head, base: base, gh_path: gh_path }, config)
  end

  let(:head) { repo.branches.find { |b| b.name == 'feature' }.target.oid }
  let(:base) { repo.branches.find { |b| b.name == 'master' }.target.oid }

  let(:repo) { change_patterns_test_repo }
  let(:gh_path) { 'owner/repo' }

  let!(:project) do
    FactoryGirl.create(:project, gh_path: gh_path, min_support: project_min_support)
  end
  let(:project_min_support) { 1 }

  let(:config) { { min_confidence: min_confidence, ignore: ignore } }
  let(:min_confidence) { 0.5 }
  let(:ignore) { {} }

  before { stub_const("#{described_class}::MAX_CHANGESET_SIZE", max_changeset_size) }
  let(:max_changeset_size) { 10 }

  let(:files_in_last_commit) do
    %w(Gemfile app.rb app_controller.rb app_template.html).freeze
  end

  it 'defines a name' do
    expect(described_class::NAME).to eql('ChangePatterns')
  end

  describe '.comments' do
    subject(:comments) { report.comments }
    let(:controller_comment) { comments.find { |c| c[:index] == 'app_controller.rb' } }

    # Setting this means we won't call into MinSupportFinder
    let(:project_min_support) { 2 }

    context 'when there is insufficient support' do
      let(:project_min_support) { 5 }

      it { is_expected.to be_empty }
    end

    context 'when there is insufficient confidence' do
      let(:min_confidence) { 0.8 }

      it { is_expected.to be_empty }
    end

    context 'when changeset sizes were too large' do
      let(:max_changeset_size) { 1 }

      it { is_expected.to be_empty }
    end

    context 'when suggestion is in user defined ignore' do
      let(:ignore) { { 'app_controller.rb' => ['app_template.html'] } }

      it { is_expected.to be_empty }
    end

    context 'when ignore antecedent is not for comment antecedent' do
      let(:ignore) { { 'app_controller.rb' => ['not_app_template.html'] } }

      it { is_expected.not_to be_empty }
    end

    context 'when min_support on project is 0' do
      let(:project_min_support) { 0 }

      it 'calls MinSupportFinder.find' do
        expect(Diggit::Analysis::ChangePatterns::MinSupportFinder).
          to receive(:find).
          with(project, anything, files_in_last_commit).
          and_return(2)
        comments
      end
    end

    context 'when sufficient support and confidence' do
      it 'comments' do
        expect(controller_comment).to include(
          report: 'ChangePatterns',
          index: 'app_controller.rb',
          location: nil,
          message: /was modified in 75% of past changes involving/,
          meta: {
            missing_file: 'app_controller.rb',
            confidence: 0.75,
            antecedent: ['app_template.html'],
          }
        )
      end
    end
  end
end
