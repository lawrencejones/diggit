require 'diggit/analysis/change_patterns/apriori'

# The plan is to implement this absolutely correct in pure ruby, then write rust
# extensions to replace each function one at a time.
RSpec.describe(Diggit::Analysis::ChangePatterns::Apriori) do
  subject(:apriori) { described_class.new(transactions, conf) }
  let(:transactions) do
    { '100' => [1, 3, 4],
      '200' => [2, 3, 5],
      '300' => [1, 2, 3, 5],
      '400' => [2, 5] }
  end
  # Resultant itemsets, after running apriori
  let(:itemsets) do
    [
      { items: [1], support: 2 },
      { items: [2], support: 3 },
      { items: [3], support: 3 },
      { items: [5], support: 3 },
      { items: [1, 3], support: 2 },
      { items: [2, 3], support: 2 },
      { items: [2, 5], support: 3 },
      { items: [3, 5], support: 2 },
      { items: [2, 3, 5], support: 2 },
    ]
  end

  def mock_itemset(items)
    { items: items, support: 0, generators: Set[], extensions: Set[] }
  end

  def lk_find(items)
    lk.find { |l| l[:items] == items }
  end

  def lk_index(items)
    lk.index { |l| l[:items] == items }
  end

  let(:conf) do
    { min_support: min_support, min_confidence: min_confidence,
      min_items: min_items, max_items: max_items }
  end
  let(:min_support) { 2 }
  let(:min_confidence) { 0.1 }
  let(:min_items) { 1 }
  let(:max_items) { 50 }

  let(:lk_3) do
    [
      mock_itemset([1, 2, 3]),
      mock_itemset([1, 2, 4]),
      mock_itemset([1, 3, 4]),
      mock_itemset([1, 3, 5]),
      mock_itemset([2, 3, 4]),
    ].shuffle # ensure each test verified indexes are set correctly
  end

  describe '.apriori' do
    subject { apriori.apriori }
    it { is_expected.to include(*itemsets) }
  end

  describe '.apriori_tid' do
    subject { apriori.apriori_tid }
    it { is_expected.to include(*itemsets) }
  end

  describe '.large_one_itemsets' do
    subject(:itemsets) { apriori.large_one_itemsets }
    let(:min_support) { 2 }

    it 'does not include items with < min_support' do
      expect(itemsets.map { |i| i[:items] }).not_to include([4])
    end

    it 'includes items with >= min_support, plus the support count' do
      expect(itemsets).to include(hash_including(items: [1], support: 2))
      expect(itemsets).to include(hash_including(items: [2], support: 3))
      expect(itemsets).to include(hash_including(items: [3], support: 3))
      expect(itemsets).to include(hash_including(items: [3], support: 3))
    end
  end

  describe '.gen' do
    subject(:candidates) { apriori.gen(lk) }
    let(:lk) { lk_3 }

    let(:lk_123) { lk_find([1, 2, 3]) }
    let(:lk_124) { lk_find([1, 2, 4]) }
    let(:candidate_1234) { candidates.find { |j| j[:items] == [1, 2, 3, 4] } }

    it 'produces only one joined set, after pruning' do
      expect(candidates.size).to be(1)
    end

    it 'sets generators on new candidates' do
      expect(candidate_1234[:generators]).
        to match(Set[lk.index(lk_123), lk.index(lk_124)])
    end

    it 'sets extensions on k-1 candidates' do
      candidates # run generation
      expect(lk_123[:extensions]).to include(0)
      expect(lk_124[:extensions]).to include(0)
    end
  end

  describe '.gen_join' do
    subject(:joined) { apriori.gen_join(lk) }

    let(:lk) { lk_3 }

    let(:joined_1234) { joined.find { |j| j[:items] == [1, 2, 3, 4] } }
    let(:joined_1345) { joined.find { |j| j[:items] == [1, 3, 4, 5] } }

    its(:size) { is_expected.to be(2) }

    it 'produces sets of one greater arity' do
      joined.each do |itemset|
        expect(itemset[:items].size).to be(lk.first[:items].size + 1)
      end
    end

    it 'sets generator fields of new itemsets' do
      expect(joined_1234[:generators]).
        to match(Set[lk_index([1, 2, 3]), lk_index([1, 2, 4])])
      expect(joined_1345[:generators]).
        to match(Set[lk_index([1, 3, 4]), lk_index([1, 3, 5])])
    end
  end

  describe '.gen_prune' do
    subject(:pruned) { apriori.gen_prune(lk, candidates) }

    let(:lk) { lk_3 }
    let(:candidates) { [mock_itemset([1, 2, 3, 4]), mock_itemset([1, 3, 4, 5])] }
    let(:result) { [[1, 2, 3, 4]] }

    its(:size) { is_expected.to be(1) }

    it 'prunes bad candidates' do
      expect(pruned).not_to include(hash_including(items: [1, 2, 4, 5]))
    end

    it 'keeps good candidate' do
      expect(pruned).to include(hash_including(items: [1, 2, 3, 4]))
    end
  end
end
