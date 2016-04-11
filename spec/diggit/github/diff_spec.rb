require 'diggit/github/diff'

RSpec.describe(Diggit::Github::Diff) do
  subject(:diff) { described_class.new(unifed_diff) }
  let(:unifed_diff) { load_fixture('github_client/pull_diff.unified') }

  describe '#index_for' do
    context 'with valid line number' do
      context 'with negative diff' do
        it 'gets index for new file diff' do
          expect(diff.index_for('lib/diggit.rb', 25)).to eql(10)
        end
      end

      context 'within block' do
        it 'one gets index' do
          expect(diff.index_for('Gemfile.lock', 51)).to eql(5)
        end

        it 'two gets index' do
          expect(diff.index_for('Gemfile.lock', 146)).to eql(12)
        end

        it 'three gets index' do
          expect(diff.index_for('Gemfile.lock', 196)).to eql(25)
        end
      end
    end
  end
end
