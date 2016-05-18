require 'diggit/analysis/change_patterns/changeset_generator'

def changeset_generator_test_repo
  TemporaryAnalysisRepo.create do |repo|
    repo.write('a', '1')
    repo.write('b', '1')
    repo.commit('1')

    repo.write('a', '2')
    repo.write('c', '2')
    repo.commit('2')

    repo.write('d', '3')
    repo.write('e', '3')
    repo.commit('3')
  end
end

RSpec.describe(Diggit::Analysis::ChangePatterns::ChangesetGenerator) do
  subject(:generator) { described_class.new(repo) }
  let(:repo) { changeset_generator_test_repo }

  describe '.changesets' do
    subject(:changesets) { generator.changesets }

    it { is_expected.to include(match_array(%w(a b))) }
    it { is_expected.to include(match_array(%w(a c))) }
    it { is_expected.to include(match_array(%w(d e))) }
  end
end
