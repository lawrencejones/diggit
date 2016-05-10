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

  let(:head) { repo.head.target.oid }
  let(:base) do
    Rugged::Walker.new(repo).tap do |w|
      w.sorting(Rugged::SORT_DATE | Rugged::SORT_REVERSE)
      w.push(repo.head.target)
    end.first.oid
  end

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
      File.write(File.join(repo.workdir, 'new_file'), 'contents')
      repo.index.add(path: 'new_file', mode: 0100644,
                     oid: Rugged::Blob.from_workdir(repo, 'new_file'))
      commit_tree = repo.index.write_tree
      repo.index.write
      person = { email: 'e', name: 'n', time: Time.now }
      Rugged::Commit.create(repo, message: 'a new commit', tree: commit_tree,
                            author: person, committer: person,
                            parents: [repo.head.target].compact, update_ref: 'HEAD')
    end
  end

  before { stub_const('Diggit::Analysis::Pipeline::REPORTERS', reporters) }
  let(:reporters) { [mock_reporter(%w(1a 1b)), mock_reporter(%w(2a 2b))] }

  context 'when the given HEAD sha is not in repo' do
    let(:head) { 'a' * 40 }
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
          expect(repo.head.target.oid).to eql(head)
          expect(File.exist?(File.join(repo.workdir, 'new_file'))).to be(false)
        end
      end

      it 'does not persist index or checkout' do
        comments = pipeline.aggregate_comments
        expect(comments).to eql(['ran mutating_reporter', 'ran_verifying_reporter'])
      end
    end
  end
end
