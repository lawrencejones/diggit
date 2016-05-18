RSpec.shared_examples 'frequent pattern miner' do
  subject(:miner) { described_class.new(diggit_changesets, min_support: 5) }
  let(:diggit_changesets) do
    load_json_fixture('changesets/diggit.json').select { |cs| cs.size.between?(1, 25) }
  end

  describe '.frequent_itemsets' do
    subject(:frequent_itemsets) { miner.frequent_itemsets }

    it 'computes correct support for each frequent itemset' do
      frequent_itemsets.each do |itemset|
        occurrences = diggit_changesets.
          select { |cs| itemset[:items].to_set.subset?(cs.to_set) }
        expect(occurrences.size).to equal(itemset[:support])
      end
    end
  end
end
