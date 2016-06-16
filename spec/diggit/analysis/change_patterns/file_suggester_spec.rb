require 'diggit/analysis/change_patterns/file_suggester'

RSpec.describe(Diggit::Analysis::ChangePatterns::FileSuggester) do
  subject(:suggester) { described_class.new(changesets, files, conf) }
  let(:changesets) { load_json_fixture('frequent_pattern/diggit_changesets.json') }

  let(:conf) { { min_support: min_support } }

  let(:min_support) { 2 }

  describe '.suggest' do
    subject(:suggestion) { suggester.suggest(min_confidence) }
    let(:min_confidence) { 0.75 }

    let(:files) do
      ['Rakefile',
       'lib/diggit/analysis/refactor_diligence/report.rb',
       'spec/diggit/analysis/refactor_diligence/report_spec.rb']
    end

    it 'includes files that are above the confidence threshold' do
      expect(suggestion).
        to include('lib/diggit/analysis/pipeline.rb' => hash_including(confidence: 0.75))
    end

    it 'does not include files without sufficient confidence' do
      expect(suggestion).not_to include('Gemfile.lock', 'Gemfile')
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

      context 'with insufficient confidence' do
        let(:files) { [:a] }

        # These are to be expected, as :a and :b clearly occur together
        it { is_expected.to include(:b) }
      end

      # :c does not occur with :a or :b >75% of the time, but when we know that :a and
      # :b have changed we have enough confidence to suggest :c
      context 'with subset that implies sufficient confidence' do
        let(:files) { [:a, :b] }

        it 'suggests additional file' do
          expect(suggestion).
            to include(c: { confidence: 0.75, antecedent: match_array([:a, :b]) })
        end
      end
    end
  end
end
