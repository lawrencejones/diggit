require 'rspec'
require_relative './lines_of_code'

RSpec.describe(GitWalker::Metrics) do
  describe '.lines_of_code' do
    let(:filepath) { 'my_file_path' }
    let(:contents) do
      %(def my_method(arg)\n  method_contents\nend\n\nputs last line\n)
    end

    before { allow(File).to receive(:read).with(filepath).and_return(contents) }

    it 'counts all non-whitespace lines' do
      expect(GitWalker::Metrics.lines_of_code(filepath, double(:repo))).
        to equal(4)
    end
  end
end
