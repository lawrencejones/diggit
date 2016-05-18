require 'diggit/analysis/change_patterns/apriori'

RSpec.describe(Diggit::Analysis::ChangePatterns::Apriori) do
  subject(:apriori) { described_class.new(itemsets, conf) }
  let(:itemsets) do
    [
      [1, 3, 4],
      [2, 3, 5],
      [1, 2, 3, 5],
      [2, 5],
    ]
  end
  # Resultant itemsets, after running apriori
  let(:expected_frequent_itemsets) do
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
    described_class::Itemset.new(items)
  end

  def lk_find(items)
    lk.find { |l| l.items == items }
  end

  def lk_index(items)
    lk.index { |l| l.items == items }
  end

  let(:conf) do
    { min_support: min_support, min_items: min_items, max_items: max_items }
  end
  let(:min_support) { 2 }
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

  describe '.frequent_itemsets' do
    subject { apriori.frequent_itemsets }
    it { is_expected.to include(*expected_frequent_itemsets) }
  end

  describe '.large_one_itemsets' do
    subject(:lk_1) { apriori.large_one_itemsets }

    it 'does not include items with < min_support' do
      expect(lk_1.map(&:items)).not_to include([4])
    end

    it 'includes items with >= min_support', :aggregate_failures do
      serialized = lk_1.map(&:to_h)
      expect(serialized).to include(hash_including(items: [1], support: 2))
      expect(serialized).to include(hash_including(items: [2], support: 3))
      expect(serialized).to include(hash_including(items: [3], support: 3))
      expect(serialized).to include(hash_including(items: [3], support: 3))
    end
  end

  describe '.gen' do
    subject(:candidates) { apriori.gen(lk) }
    let(:lk) { lk_3 }

    let(:lk_123) { lk_find([1, 2, 3]) }
    let(:lk_124) { lk_find([1, 2, 4]) }
    let(:candidate_1234) { candidates.find { |j| j.items == [1, 2, 3, 4] } }

    it 'produces only one joined set, after pruning' do
      expect(candidates.size).to be(1)
    end

    it 'sets generators on new candidates' do
      expect(candidate_1234.generators).to match(Set[lk_123, lk_124])
    end

    it 'sets extensions on k-1 candidates' do
      candidates # run generation
      expect(lk_123.extensions).to include(candidate_1234)
      expect(lk_124.extensions).to include(candidate_1234)
    end
  end

  describe '.gen_join' do
    subject(:joined) { apriori.gen_join(lk) }

    let(:lk) { lk_3 }

    let(:joined_1234) { joined.find { |j| j.items == [1, 2, 3, 4] } }
    let(:joined_1345) { joined.find { |j| j.items == [1, 3, 4, 5] } }

    its(:size) { is_expected.to be(2) }

    it 'produces sets of one greater arity' do
      joined.each do |itemset|
        expect(itemset.items.size).to be(lk.first.items.size + 1)
      end
    end

    it 'sets generator fields of new itemsets' do
      expect(joined_1234.generators).
        to match(Set[lk_find([1, 2, 3]), lk_find([1, 2, 4])])
      expect(joined_1345.generators).
        to match(Set[lk_find([1, 3, 4]), lk_find([1, 3, 5])])
    end
  end

  describe '.gen_prune' do
    subject(:pruned) { apriori.gen_prune(lk, candidates).map(&:to_h) }

    let(:lk) { lk_3 }
    let(:candidates) { [mock_itemset([1, 2, 3, 4]), mock_itemset([1, 3, 4, 5])] }

    its(:size) { is_expected.to be(1) }

    it 'prunes bad candidates' do
      expect(pruned).not_to include(hash_including(items: [1, 2, 4, 5]))
    end

    it 'keeps good candidate' do
      expect(pruned).to include(hash_including(items: [1, 2, 3, 4]))
    end
  end
end
