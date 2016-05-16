require 'diggit/analysis/change_patterns/fp_growth'
require 'diggit/analysis/change_patterns/fp_debug' # for inspection of trees

RSpec.describe(Diggit::Analysis::ChangePatterns::FpGrowth) do
  subject(:fp_growth) { described_class.new(itemsets, conf) }
  let(:itemsets) do
    [
      %i(a d f),
      %i(a c d e),
      %i(b d),
      %i(b c d),
      %i(b c),
      %i(a b d),
      %i(b d e),
      %i(b c e g),
      %i(c d f),
      %i(a b d),
      %i(a b c d e f), # to be filtered
    ]
  end

  let(:conf) { { min_support: min_support, min_items: min_items, max_items: max_items } }
  let(:min_support) { 3 }
  let(:min_items) { 2 }
  let(:max_items) { 5 }

  # Tags in form '[item:count]'
  def find_node(heads, node_tag, parent_tag = nil)
    heads.flat_map { |item, head| head.nodes.to_a }.find do |node|
      node.to_s == node_tag && (parent_tag.nil? || node.parent.to_s == parent_tag)
    end
  end

  describe '.database' do
    subject(:database) { fp_growth.database }

    it 'removes items with less that min_support' do
      expect(database.inject(:+)).not_to include(:f, :g)
    end

    it 'removes changesets that have > max_items' do
      expect(database).not_to include(%i(f e d c b a))
    end

    it 'sorts each itemset in reverse frequency order' do
      expect(database).to include(%i(d a), %i(b c))
    end
  end

  describe '.frequent_itemsets' do
    subject(:result) { fp_growth.frequent_itemsets }

    it { is_expected.to include(items: match_array([:d]), support: 8) }
    it { is_expected.to include(items: match_array([:e]), support: 3) }
    it { is_expected.to include(items: match_array([:a]), support: 4) }
    it { is_expected.to include(items: match_array([:c, :d]), support: 3) }
    it { is_expected.to include(items: match_array([:c, :b]), support: 3) }
    it { is_expected.to include(items: match_array([:d, :b]), support: 5) }
  end

  describe '.initial_tree' do
    subject(:tree) { fp_growth.initial_tree }

    let(:d_8) { find_node(tree.heads, '[d:8]') }
    let(:b_5) { find_node(tree.heads, '[b:5]', '[d:8]') }
    let(:c_1) { find_node(tree.heads, '[c:1]', '[b:5]') }
    let(:a_2) { find_node(tree.heads, '[a:2]', '[b:5]') }

    it 'correctly counts each head' do
      expect(tree.heads.values.map(&:to_s)).
        to include(*%w([d:8] [b:7] [c:5] [a:4] [e:3]))
    end

    # Verify all nodes with unique counts
    it 'links each node to its parent', :aggregate_failures do
      expect(d_8.parent).to be_nil
      expect(b_5.parent).to be(d_8)
      expect(c_1.parent).to be(b_5)
      expect(a_2.parent).to be(b_5)
    end

    it 'makes every node reachable via a head', :aggregate_failures do
      expect(tree.heads[:d].nodes.to_a.uniq.size).to be(1)
      expect(tree.heads[:b].nodes.to_a.uniq.size).to be(2)
      expect(tree.heads[:c].nodes.to_a.uniq.size).to be(3)
      expect(tree.heads[:a].nodes.to_a.uniq.size).to be(3)
      expect(tree.heads[:e].nodes.to_a.uniq.size).to be(3)
    end
  end

  describe '.project_tree' do
    subject(:projected) { fp_growth.send(:project_tree, source, item) }
    # Relies upon correctness of initial_tree
    let(:source) { fp_growth.initial_tree }
    let(:item) { :e }

    let(:d_2) { find_node(projected.heads, '[d:2]') }
    let(:b_1) { find_node(projected.heads, '[b:1]', '[d:2]') }
    let(:c_1) { find_node(projected.heads, '[c:1]', '[d:2]') }
    let(:a_1) { find_node(projected.heads, '[a:1]', '[c:1]') }

    it 'generates correct head counts' do
      expect(projected.heads.values.map(&:to_s)).
        to include(*%w([d:2] [b:2] [c:2] [a:1]))
    end

    it 'links each node to parent', :aggregate_failures do
      expect(d_2.parent).to be_nil
      expect(b_1.parents.map(&:to_s)).to eql(['[d:2]'])
      expect(c_1.parents.map(&:to_s)).to eql(['[d:2]'])
      expect(a_1.parents.map(&:to_s)).to eql(['[c:1]', '[d:2]'])
    end

    it 'clears auxiliary pointers on original tree' do
      projected
      source.heads.flat_map { |_, head| head.nodes.to_a }.each do |node|
        expect(node.aux).to be_nil
      end
    end
  end
end
