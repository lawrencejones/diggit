require 'diggit/analysis/change_patterns/min_support_finder'
require 'diggit/analysis/change_patterns/fp_growth'

RSpec.describe(Diggit::Analysis::ChangePatterns::MinSupportFinder) do
  subject(:finder) { described_class.new(algorithm, changesets, current_files) }

  let(:algorithm) { Diggit::Analysis::ChangePatterns::FpGrowth }
  let(:changesets) { [] }
  let(:current_files) { %w(a.rb b.rb c.rb d.rb e.rb) }

  let(:grower_instant_below_threshold) do
    instance_of(algorithm).tap do |grower|
      allow(grower).to receive(:frequent_itemsets).
        and_return([ # 20%!
                     { items: Hamster::SortedSet['c.rb'], support: 2 },
                   ])
    end
  end

  let(:grower_instant_above_threshold) do
    instance_of(algorithm).tap do |grower|
      allow(grower).to receive(:frequent_itemsets).
        and_return([ # 60%!
                     { items: Hamster::SortedSet['a.rb', 'b.rb'], support: 3 },
                     { items: Hamster::SortedSet['c.rb'], support: 2 },
                   ])
    end
  end

  let(:grower_timeout) do
    instance_of(algorithm).tap do |grower|
      allow(grower).to receive(:frequent_itemsets) do
        raise(Timeout::Error)
      end
    end
  end

  let(:timeout) { 1.second }
  let(:files_included_threshold) { 0.3 }
  let(:initial_support) { 10 }

  before do
    stub_const("#{described_class}::TIMEOUT", timeout)
    stub_const("#{described_class}::FILES_INCLUDED_THRESHOLD", files_included_threshold)
    stub_const("#{described_class}::INITIAL_SUPPORT", initial_support)
  end

  # Allow Algorithm being instantiated with `min_support` to yield `grower`
  def mock_grower(min_support, grower)
    allow(algorithm).
      to receive(:new).
      with(changesets, min_support: min_support).
      and_return(grower)
  end

  describe '.find' do
    subject(:find) { described_class.find(project, changesets, current_files) }

    context 'when project already has min_support value' do
      let(:project) { FactoryGirl.build_stubbed(:project, min_support: 1) }

      it { is_expected.to be(project.min_support) }
    end

    context 'when project does not have calibrated min_support' do
      let(:project) { FactoryGirl.create(:project, min_support: 0) }

      it 'computes min support using MinSupportFinder, saving to project' do
        expect(described_class).
          to receive(:new).
          with(Diggit::Analysis::ChangePatterns::FpGrowth, changesets, current_files).
          and_return(instance_double(described_class, support: 5))
        expect { find }.
          to change { project.reload.min_support }.
          from(0).to(5)
        expect(find).to be(5)
      end
    end
  end

  describe '#support' do
    context 'when limited by algorithm performance' do
      before do
        mock_grower(initial_support - 0, grower_instant_below_threshold)
        mock_grower(initial_support - 1, grower_instant_below_threshold)
        mock_grower(initial_support - 2, grower_timeout)
      end

      it 'returns the next best support value' do
        expect(finder.support).to be(initial_support - 1)
      end
    end

    context 'when threshold is reached before timeout' do
      before do
        mock_grower(initial_support - 0, grower_instant_below_threshold)
        mock_grower(initial_support - 1, grower_instant_below_threshold)
        mock_grower(initial_support - 2, grower_instant_above_threshold)
      end

      it 'returns support value that yields threshold' do
        expect(finder.support).to be(initial_support - 2)
      end
    end
  end
end
