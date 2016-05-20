require 'diggit/analysis/change_patterns/file_suggester'

RSpec.describe(Diggit::Analysis::ChangePatterns::FileSuggester) do
  subject(:suggester) do
    described_class.new(frequent_itemsets, min_confidence: min_confidence)
  end
  let(:min_confidence) { 0.75 }

  let(:frequent_itemsets) do
    load_json_fixture('frequent_pattern/diggit_frequent_patterns.json').map do |is|
      { items: Hamster::Set.new(is['items']), support: is['support'] }
    end
  end

  describe '.suggest' do
    subject(:suggestions) { suggester.suggest(files) }
    let(:files) do
      ['Rakefile',
       'lib/diggit/analysis/refactor_diligence/report.rb',
       'spec/diggit/analysis/refactor_diligence/report_spec.rb']
    end

    it 'includes files that are above the confidence threshold' do
      expect(suggestions).
        to include('lib/diggit/analysis/pipeline.rb' => hash_including(confidence: 0.75))
    end

    it 'does not include files without sufficient confidence' do
      expect(suggestions).not_to include('Gemfile.lock', 'Gemfile')
    end

    context 'with conditional confidence' do
      # If we have Items={a b c}, and our changesets are...
      let(:changesets) do
        [
          %i(a),
          %i(b),
          %i(a b),
          %i(a b c),
          %i(a b c),
          %i(a b c),
        ]
      end

      # From changesets, we have these frequent itemsets...
      let(:frequent_itemsets) do
        [
          { items: %i(a), support: 5 },
          { items: %i(b), support: 5 },
          { items: %i(c), support: 3 },
          { items: %i(a b), support: 4 },
          { items: %i(b c), support: 3 },
          { items: %i(a b c), support: 3 },
        ].map { |is| is.merge(items: Hamster::Set.new(is[:items])) }
      end

      it 'will make a suggestion if a subset of the given files implies confidence' do
        # These are to be expected, as :a and :b clearly occur together
        expect(suggester.suggest([:a])).to include(:b)
        expect(suggester.suggest([:b])).to include(:a)

        # :c does not occur with :a or :b >75% of the time, but when we know that :a and
        # :b have changed we have enough confidence to suggest :c
        expect(suggester.suggest([:a, :b])).
          to include(c: { confidence: 0.75, antecedent: [:a, :b] })
      end
    end
  end
end
