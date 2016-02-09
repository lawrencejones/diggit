require 'rspec'
require_relative './whitespace_complexity'

def load_code_fixture(filename)
  File.read(File.join(File.dirname(__FILE__), '../../../fixtures/code', filename))
end

RSpec.describe(GitWalker::Metrics::WhitespaceComplexity) do
  subject(:metric) { described_class.new(contents) }

  shared_examples(described_class) do |file, expected|
    let(:contents) { load_code_fixture(file) }

    context "for #{file}" do
      describe '.complexity' do
        before { allow(metric).to receive(:indent).and_return(expected[:indent]) }
      end

      describe '.indent' do
        subject { metric.send(:indent) }
        it { is_expected.to eql(expected[:indent]) }
      end
    end
  end

  it_behaves_like(described_class, 'ruby_file.rb', indent: '  ')
  it_behaves_like(described_class, 'Makefile', indent: "\t")
  it_behaves_like(described_class, 'javascript_file.js', indent: '  ')
  it_behaves_like(described_class, 'python_file.py', indent: '    ')
end
