require 'diggit/analysis/refactor_diligence/method_size_history'

RSpec.describe(Diggit::Analysis::RefactorDiligence::MethodSizeHistory) do
  subject(:instance) { described_class.new(repo, head: 'head', files: [file]) }
  let(:repo) { instance_double(Rugged::Repository) }
  let(:file) { 'file.rb' }

  before do
    allow(instance).
      to receive(:rev_list).
      with(path: file, commit: 'head').
      and_return(%i(third second first))

    allow(instance).to receive(:scan).
      with(file, :first).
      and_return('fetch' => 3, 'bad_idea' => 5)

    allow(instance).to receive(:scan).
      with(file, :second).
      and_return('fetch' => 2, 'push' => 3)

    allow(instance).to receive(:scan).
      with(file, :third).
      and_return('fetch' => 5, 'push' => 3)
  end

  describe '.history' do
    subject(:history) { instance.history.to_h }

    it 'only tracks methods present in first commit' do
      expect(history.keys).not_to include('bad_idea')
    end

    it 'stops tracking after refactor (size reduction)' do
      expect(history['fetch']).not_to include([3, :first])
    end

    it 'aggregates method sizes into sha-size tuples' do
      expect(history).to include('fetch' => [[5, :third], [2, :second]])
    end

    it 'removes duplicate entries for same size, taking oldest sha' do
      expect(history).to include('push' => [[3, :second]])
    end
  end
end
