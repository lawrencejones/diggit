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
      expect(suggestions).to include('lib/diggit/analysis/pipeline.rb' => 0.75)
    end

    it 'does not include files without sufficient confidence' do
      expect(suggestions).not_to include('Gemfile.lock', 'Gemfile')
    end
  end
end
