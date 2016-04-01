require 'utils/git_walker/metrics/complexity'

RSpec.describe(GitWalker::Metrics::WhitespaceAnalysis) do
  subject(:metric) { described_class.new(contents) }

  describe '.std' do
    subject { metric.std }

    context 'for one line file' do
      let(:contents) { %(5.1.1\n) } # .node-version

      it { is_expected.to equal(0.0) }
    end

    context 'for file without any indent' do
      let(:contents) { %(.DS_Store\n.env\nnode_modules/\n*.log\n) } # .gitignore

      it { is_expected.to equal(0.0) }
    end
  end

  shared_examples(described_class) do |file, expected|
    let(:contents) { load_fixture(File.join('code', file)) }

    context "for #{file}" do
      describe '.std' do
        subject { metric.std }
        before { allow(metric).to receive(:nominal_indent).and_return(expected[:indent]) }

        it { is_expected.to be_within(0.1).of(expected[:std]) }
      end

      describe '.nominal_indent' do
        subject { metric.nominal_indent }

        it { is_expected.to eql(expected[:indent]) }
      end
    end
  end

  it_behaves_like(described_class, 'ruby_file.rb', indent: '  ', std: 0.75)
  it_behaves_like(described_class, 'Makefile', indent: "\t", std: 0.53)
  it_behaves_like(described_class, 'javascript_file.js', indent: '  ', std: 0.77)
  it_behaves_like(described_class, 'python_file.py', indent: '    ', std: 0.81)
end
