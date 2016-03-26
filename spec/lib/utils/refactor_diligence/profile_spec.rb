require 'hamster/hash'
require 'utils/refactor_diligence/profile'

RSpec.describe(RefactorDiligence::Profile) do
  subject(:profile) { described_class.new(repo_double) }
  let(:repo_double) { double(:repo) }

  before do
    allow(profile).
      to receive(:method_sizes).
      and_return(method_sizes)
  end

  # never - does not change in size
  # once, once_also - is increased once in size
  # twice, twice_also - is increased twice in size
  # changing - changes size, should be tracked until decrease is detected
  let(:method_sizes) do
    [
      {
        'Child::never' => 1,
        'Child::once' => 2,
        'Child::once_also' => 2,
        'Child::twice' => 3,
        'Child::twice_also' => 3,
        'Child::changing' => 3,
      },
      {
        'Child::never' => 1,
        'Child::once' => 1,
        'Child::once_also' => 2,
        'Child::twice' => 2,
        'Child::twice_also' => 2,
        'Child::changing' => 2,
      },
      {
        'Child::never' => 1,
        'Child::once' => 1,
        'Child::once_also' => 1,
        'Child::twice' => 1,
        'Child::twice_also' => 1,
        'Child::changing' => 3,
      },
    ].map { |hash| Hamster::Hash.new(hash) }
  end

  describe('.array_profile') do
    subject { profile.array_profile }

    it { is_expected.to eql([1, 3, 2]) }
  end

  describe('.method_histories') do
    subject { profile.method_histories }

    it 'correctly stores historic method sizes' do
      is_expected.to match('Child::never' => [1],
                           'Child::once' => [2, 1],
                           'Child::once_also' => [2, 1],
                           'Child::twice' => [3, 2, 1],
                           'Child::twice_also' => [3, 2, 1],
                           'Child::changing' => [3, 2])
    end
  end
end
