require_relative 'temporary_analysis_repo'
require 'diggit/analysis/pipeline'

# rubocop:disable Style/AlignParameters
def pipeline_test_repo
  TemporaryAnalysisRepo.create do |repo|
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
  end
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
      define_method(:initialize) { |repo, conf| yield repo if block }
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

  context 'when the given HEAD sha is not in repo' do
    let(:head) { 'bad-head-reference' }
    it 'raises Pipeline::BadGitHistory' do
      expect { pipeline }.to raise_exception(described_class::BadGitHistory)
    end
  end

  describe '#aggregate_comments' do
    it 'collects comments from all reporters' do
      expect(pipeline.aggregate_comments).to match_array(%w(1a 1b 2a 2b))
    end

    it 'logs running each reporter' do
      allow(pipeline.logger).to receive(:info) do |prefix, &block|
        expect(prefix).to eql('Diggit::Analysis::Pipeline')
        expect(block.call).to match(/\[\S+\] \S+\.\.\./)
      end
      pipeline.aggregate_comments
    end

    context 'with bad mutating reporters' do
      let(:reporters) { [mutating_reporter, verifying_reporter] }
      let(:verifying_reporter) do
        mock_reporter(['ran_verifying_reporter']) do |repo|
          expect(repo.gblob('HEAD').sha).to eql(head)
          expect(File.exist?(File.join(repo.dir.path, 'new_file'))).to be(false)
        end
      end

      it 'does not persist index or checkout' do
        comments = pipeline.aggregate_comments
        expect(comments).to eql(['ran mutating_reporter', 'ran_verifying_reporter'])
      end
    end
  end
end
