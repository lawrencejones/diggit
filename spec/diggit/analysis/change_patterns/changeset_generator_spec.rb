require 'diggit/analysis/change_patterns/changeset_generator'

def changeset_generator_test_repo
  TemporaryAnalysisRepo.create do |repo|
    repo.write('a', '1')
    repo.write('b', '1')
    repo.commit('1')

    repo.write('a', '2')
    repo.write('c', '2')
    repo.write('to_be_deleted', '2')
    repo.commit('2')

    repo.write('d', '3')
    repo.write('e', '3')
    repo.rm('to_be_deleted')
    repo.commit('3')
  end
end

RSpec.describe(Diggit::Analysis::ChangePatterns::ChangesetGenerator) do
  subject(:generator) { described_class.new(repo, gh_path: gh_path, head: head) }
  let(:repo) { changeset_generator_test_repo }
  let(:gh_path) { 'owner/repo' }
  let(:head) { nil }

  describe '.changesets' do
    subject(:changesets) { generator.changesets }
    let(:cached) { Diggit::Services::Cache.get('owner/repo/changesets') }

    it { is_expected.to include(match_array(%w(a b))) }
    it { is_expected.to include(match_array(%w(a c to_be_deleted))) }
    it { is_expected.to include(match_array(%w(d e to_be_deleted))) }

    it 'does not include commits that have no changes' do
      is_expected.not_to include([])
    end

    it 'persists commit changeset hash to diggit cache, including deleted files' do
      changesets
      expect(cached.map { |entry| entry[:changeset] }).
        to eql([%w(d e to_be_deleted),
                %w(a c to_be_deleted),
                %w(a b)])
    end

    it 'does not include merge commits'

    context 'with given head' do
      let(:head) { repo.last_commit.parents.first.oid }

      it 'returns only changesets from before head' do
        expect(changesets.size).to be(2)
        expect(changesets).not_to include(%w(d e))
      end
    end

    context 'when running with active cache' do
      it 'stops walking repo early' do
        changesets # fill cache
        generator_two = described_class.new(repo, gh_path: gh_path)
        # generate_commit_changesets only returns fresh commit changesets, so the size
        # will tell us how many commits were walked
        expect(generator_two.send(:generate_commit_changesets).size).to equal(0)
      end
    end
  end
end
