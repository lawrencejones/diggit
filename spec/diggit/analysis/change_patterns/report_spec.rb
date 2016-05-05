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
    repo.write 'app_controller.rb', <<-RUBY
    class AppController
      def render_template
        render('app_template.html')
      end
    end
    RUBY
    repo.commit('render app_template')

    repo.write('app_template.html', '<html> @first </html>')
    repo.write 'app_controller.rb', <<-RUBY
    class AppController
      def render_template
        render('app_template.html', first: 'first')
      end
    end
    RUBY
    repo.commit('@first param for app_template render')

    repo.write('app_template.html', '<html> @first @second</html>')
    repo.write 'app_controller.rb', <<-RUBY
    class AppController
      def render_template
        render('app_template.html', first: 'first', second: 'second')
      end
    end
    RUBY
    repo.commit('@second param for app_template render')

    # Create suspect feature branch
    repo.branch('feature').checkout
    repo.write('app_template.html', '<html> @first @second @third </html>')
    repo.commit('@third param for app_template')
  end
end
# rubocop:enable Metrics/MethodLength

RSpec.describe(Diggit::Analysis::ChangePatterns::Report) do
  subject(:report) { described_class.new(repo, head: head, base: base) }

  let(:head) { repo.branches.find { |b| b.name == 'feature' }.target.oid }
  let(:base) { repo.branches.find { |b| b.name == 'master' }.target.oid }

  let(:repo) { change_patterns_test_repo }

  before do
    stub_const("#{described_class}::MIN_SUPPORT", min_support)
    stub_const("#{described_class}::MIN_CONFIDENCE", min_confidence)
    stub_const("#{described_class}::MAX_CHANGESET_SIZE", max_changeset_size)
  end

  let(:min_support) { 1 }
  let(:min_confidence) { 0.5 }
  let(:max_changeset_size) { 10 }

  describe '.comments' do
    subject(:comments) { report.comments }
    let(:controller_comment) { comments.find { |c| c[:index] == 'app_controller.rb' } }

    context 'when there is insufficient support' do
      let(:min_support) { nil }

      it { is_expected.to be_empty }
    end

    context 'when there is insufficient confidence' do
      let(:min_confidence) { nil }

      it { is_expected.to be_empty }
    end

    context 'when changeset sizes were too large' do
      let(:max_changeset_size) { 1 }

      it { is_expected.to be_empty }
    end

    context 'when sufficient support and confidence' do
      it 'comments' do
        expect(controller_comment).to include(
          report: 'ChangePatterns',
          index: 'app_controller.rb',
          location: 'app_controller.rb:1',
          message: /was expected to be modified in this change/,
          meta: {
            missing_file: 'app_controller.rb',
            confidence: 0
          }
        )
      end
    end
  end
end
