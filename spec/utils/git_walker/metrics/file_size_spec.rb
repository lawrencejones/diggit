require 'utils/git_walker/metrics/file_size'

RSpec.describe(GitWalker::Metrics) do
  describe '.file_size' do
    let(:filepath) { 'my_file_path' }
    let(:filesize) { 10 }

    before { allow(File).to receive(:size).with(filepath).and_return(filesize) }

    it 'returns correct file size' do
      expect(GitWalker::Metrics.file_size(filepath, double(:repo))).
        to equal(filesize)
    end
  end
end
