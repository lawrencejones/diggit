require 'diggit/analysis/refactor_diligence/method_size_history'

RSpec.describe(Diggit::Analysis::RefactorDiligence::MethodSizeHistory) do
  subject(:instance) { described_class.new(repo) }
  let(:repo) { instance_double(Git::Base) }

  let(:commits) { [:third_commit, :second_commit, :first_commit] }

  before do
    allow(instance).to receive(:scan).
      with(:first_commit, files: anything).
      and_return('fetch' => 3, 'bad_idea' => 5)

    allow(instance).to receive(:scan).
      with(:second_commit, files: anything).
      and_return('fetch' => 2, 'push' => 3)

    allow(instance).to receive(:scan).
      with(:third_commit, files: anything).
      and_return('fetch' => 5, 'push' => 3)
  end

  describe '.history' do
    subject(:history) { instance.history(commits, restrict_to: []).to_h }

    it 'stops tracking after refactor (size reduction)' do
      expect(history['fetch'].map(&:first)).not_to include(3)
    end

    it 'aggregates method sizes into sha-size tuples' do
      expect(history).to include('fetch' => [[5, :third_commit], [2, :second_commit]])
    end

    it 'removes duplicate entries for same size, taking oldest sha' do
      expect(history).to include('push' => [[3, :second_commit]])
    end
  end

  describe '.history_by_commit' do
    subject(:sizes) { instance.history_by_commit(commits, restrict_to: []) }

    its(:count) { is_expected.to eql(commits.count) }

    it 'only tracks methods present in first commit' do
      sizes.each { |(methods)| expect(methods.keys).not_to include('bad_idea') }
    end

    it 'does not list methods beyond their creation' do
      expect(sizes[2].first.keys).not_to include('push')
    end

    it 'tracks method sizes in reverse order' do
      expect(sizes[0].first.to_h).to eql('fetch' => 5, 'push' => 3)
      expect(sizes[1].first.to_h).to eql('fetch' => 2, 'push' => 3)
      expect(sizes[2].first.to_h).to eql('fetch' => 3)

      expect(sizes.map(&:second)).to eql([:third_commit, :second_commit, :first_commit])
    end
  end
end
