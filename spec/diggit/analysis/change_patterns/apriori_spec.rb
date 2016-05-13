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

  let(:conf) do
    { min_support: min_support, min_confidence: min_confidence,
      min_items: min_items, max_items: max_items }
  end
  let(:min_support) { 2 }
  let(:min_confidence) { 0.1 }
  let(:min_items) { 1 }
  let(:max_items) { 50 }

  describe '.apriori_tid' do
  end

  describe '.large_one_itemsets' do
    subject(:itemsets) { apriori.large_one_itemsets }
    let(:min_support) { 2 }

    it 'does not include items with < min_support' do
      expect(itemsets).not_to include([[4], anything])
    end

    it 'includes items with >= min_support, plus the support count' do
      expect(itemsets).to include([[1], 2], [[2], 3], [[3], 3], [[3], 3])
    end
  end

  describe '.gen_join' do
    subject(:joined) { apriori.gen_join(large_itemsets) }

    let(:large_itemsets) { [[1, 2, 3], [1, 2, 4], [1, 3, 4], [1, 3, 5], [2, 3, 4]] }
    let(:result) { [[1, 2, 3, 4], [1, 3, 4, 5]] }

    it { is_expected.to eql(result) }
    it 'produces sets of one greater arity' do
      joined.each { |set| expect(set.size).to be(large_itemsets.first.size) }
    end
  end

  describe '.gen_prune' do
    subject(:pruned) { apriori.gen_prune(large_itemsets, candidates) }

    let(:large_itemsets) { [[1, 2, 3], [1, 2, 4], [1, 3, 4], [1, 3, 5], [2, 3, 4]] }
    let(:candidates) { [[1, 2, 3, 4], [1, 3, 4, 5]] }
    let(:result) { [[1, 2, 3, 4]] }

    it { is_expected.to eql(result) }
  end
end
