require_relative 'temporary_analysis_repo'
require 'diggit/analysis/pipeline'

# rubocop:disable Style/AlignParameters
def pipeline_test_repo
  TemporaryAnalysisRepo.new.tap do |repo|
    repo.write('file.c',
    %(int main(int argc, char **argv) {
        return 0;
      }))
    repo.commit('initial commit')

    repo.write('.gitignore', %(*.o))
    repo.write('file.c',
    %(int main(int argc, char **argv) {
        printf("Second commit change");
        return 0;
      }))
    repo.commit('second commit')

    repo.write('README.md',
    %(# Simple C Project
      Keep it real dawg (⌐■_■)))
    repo.write('file.c',
    %(int main(int argc, char **argv) {
        printf("Second commit change");
        printf("Third commit change");
        return 0;
      }))
    repo.commit('third commit')
  end.g
end
# rubocop:enable Style/AlignParameters

RSpec.describe(Diggit::Analysis::Pipeline) do
  subject(:pipeline) { described_class.new(repo, head: head, base: base) }
  let(:repo) { pipeline_test_repo }

  let(:head) { repo.log.first.sha }
  let(:base) { repo.log.last.sha }

  # rubocop:disable Lint/UnusedBlockArgument
  def mock_reporter(mock_comments, &block)
    Class.new do
      define_method(:initialize) { |repo, files_changed:| yield repo if block }
      define_method(:comments) { mock_comments }
    end
  end
  # rubocop:enabled Lint/UnusedBlockArgument

  let(:mutating_reporter) do
    mock_reporter(['ran mutating_reporter']) do |repo|
      File.write(File.join(repo.dir.path, 'new_file'), 'contents')
      repo.add('new_file')
      repo.commit('added new file')
    end
  end

  before { stub_const('Diggit::Analysis::Pipeline::REPORTERS', reporters) }
  let(:reporters) { [mock_reporter(%w(1a 1b)), mock_reporter(%w(2a 2b))] }

  describe '#aggregate_comments' do
    it 'collects comments from all reporters' do
      expect(pipeline.aggregate_comments).to match_array(%w(1a 1b 2a 2b))
    end

    context 'with bad mutating reporters' do
      let(:reporters) { [mutating_reporter] }

      it 'does not persist index or checkout' do
        comments = pipeline.aggregate_comments
        expect(comments).to eql(['ran mutating_reporter'])

        expect(repo.gblob('HEAD').sha).to eql(head)
        expect(File.exist?(File.join(repo.dir.path, 'new_file'))).to be(false)
      end
    end
  end

  # private

  describe '#files_changed' do
    subject { pipeline.send(:files_changed) }

    context 'for entire history' do
      let(:head) { repo.log.first.sha }
      let(:base) { repo.log.last.sha }

      it { is_expected.to match_array(%w(.gitignore file.c README.md)) }
    end

    context 'for partial history' do
      let(:head) { repo.log[0].sha }
      let(:base) { repo.log[1].sha }

      it { is_expected.to match_array(%w(README.md file.c)) }
    end
  end
end
