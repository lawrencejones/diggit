require 'utils/git_walker/metrics/lines_of_code'

RSpec.describe(GitWalker::Metrics) do
  describe '.lines_of_code' do
    subject { GitWalker::Metrics.lines_of_code(filepath, double(:repo)) }

    before { allow(File).to receive(:read).with(filepath).and_return(contents) }

    let(:filepath) { 'my_file_path' }
    let(:contents) do
      %(def my_method(arg)\n  method_contents\nend\n\nputs last line\n)
    end

    it { is_expected.to equal(4) }

    context 'when file is badly encoded' do
      before { allow(contents).to receive(:valid_encoding?).and_return(false) }

      it { is_expected.to equal(0) }
    end
  end
end
