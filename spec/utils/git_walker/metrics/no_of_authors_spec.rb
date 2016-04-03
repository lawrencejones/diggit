require 'utils/git_walker/metrics/no_of_authors'

RSpec.describe(GitWalker::Metrics) do
  describe '.no_of_authors' do
    let(:file) { 'my_file_path' }

    let(:repo) do
      double(:repo).tap do |repo|
        allow(repo).
          to receive(:gblob).
          with(file).and_return(blob)
      end
    end

    let(:blob) do
      double(:blob).tap do |blob|
        allow(blob).
          to receive(:log).
          and_return([
                       double(author: double(email: 'a')),
                       double(author: double(email: 'b')),
                       double(author: double(email: 'a')),
                     ])
      end
    end

    it 'counts unique authors' do
      expect(GitWalker::Metrics.no_of_authors(file, repo)).
        to equal(2)
    end
  end
end
