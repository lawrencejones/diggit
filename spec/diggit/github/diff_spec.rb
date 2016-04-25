require 'octokit'
require 'diggit/github/diff'

RSpec.describe(Diggit::Github::Diff) do
  subject(:diff) { described_class.new(unifed_diff, base: base, head: head) }
  let(:unifed_diff) { load_fixture('github_client/pull_diff.unified') }

  let(:base) { 'base-sha' }
  let(:head) { 'head-sha' }

  describe '.from_pull_request' do
    let(:repo) { 'lawrencejones/diggit' }
    let(:pull) { 9 }
    let(:client) { instance_double(Octokit::Client) }

    before do
      allow(client).
        to receive(:pull_request).
        with(repo, pull).
        and_return(base: { sha: 'base-sha' }, head: { sha: 'head-sha' })

      allow(client).
        to receive(:compare).
        with(repo, 'base-sha', 'head-sha',
             accept: Diggit::Github::Diff::GITHUB_DIFF_FORMAT).
        and_return('unified-diff-text')
    end

    it 'initializes an Diff instance' do
      expect(described_class).
        to receive(:new).
        with('unified-diff-text', base: 'base-sha', head: 'head-sha').
        and_call_original

      expect(described_class.from_pull_request(repo, pull, client)).
        to be_instance_of(described_class)
    end
  end

  describe '#index_for' do
    context 'with valid line number' do
      context 'with negative diff' do
        it 'gets index for latest file diff' do
          expect(diff.index_for('lib/diggit.rb', 25)).to eql(10)
        end
      end

      context 'on newly created file' do
        it 'gets index' do
          expect(diff.index_for('file.rb', 3)).to eql(3)
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

    context 'with line number that is not in this diff' do
      it 'returns nil' do
        expect(diff.index_for('lib/diggit.rb', 1)).to be_nil
      end
    end

    context 'with file not in diff' do
      it 'raises FileNotFound exception' do
        expect { diff.index_for('i_dont_exist.brainfuck', 1) }.
          to raise_error(Diggit::Github::Diff::FileNotFound)
      end
    end
  end
end
