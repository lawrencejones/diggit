RSpec.shared_examples 'frequent pattern miner' do
  subject(:miner) { described_class.new(diggit_changesets, min_support: 5) }

  let(:diggit_changesets) { load_json_fixture('frequent_pattern/diggit_changesets.json') }
  # These are sorted lexicographically
  let(:diggit_frequent_itemsets) do
    load_json_fixture('frequent_pattern/diggit_frequent_itemsets.json')
  end

  describe '.frequent_itemsets' do
    subject(:frequent_itemsets) { miner.frequent_itemsets }

    it 'produces correct frequent itemsets' do
      frequent_itemsets.each do |is|
        expect(diggit_frequent_itemsets).
          to include('items' => is[:items].sort, 'support' => is[:support])
      end
      expect(frequent_itemsets.size).to be(diggit_frequent_itemsets.size)
    end

    it 'computes correct support for each frequent itemset' do
      frequent_itemsets.each do |itemset|
        occurrences = diggit_changesets.
          select { |cs| itemset[:items].to_set.subset?(cs.to_set) }
        expect(itemset).to match(hash_including(support: occurrences.size))
      end
    end
  end
end
