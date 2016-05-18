require 'diggit/analysis/change_patterns/file_suggester'

RSpec.describe(Diggit::Analysis::ChangePatterns::FileSuggester) do
  subject(:suggester) { described_class.new(frequent_itemsets) }

  let(:frequent_itemsets) do
    [
      { items: ['CHANGELOG.md', 'app.rb'], support: 4 },
      { items: ['CHANGELOG.md'], support: 9 },
      { items: ['app.rb'], support: 4 },
      { items: ['Gemfile', 'Gemfile.lock'], support: 4 },
      { items: ['Gemfile'], support: 6 },
      { items: ['Gemfile.lock'], support: 4 },
    ]
  end

  describe '.suggest' do
    it 'includes files that are above the confidence threshold' do
      expect(suggester.suggest('app.rb')).to include('CHANGELOG.md')
      expect(suggester.suggest('Gemfile.lock')).to include('Gemfile')
    end

    it 'does not include files without sufficient confidence' do
      expect(suggester.suggest('CHANGELOG.md')).not_to include('app.rb')
    end
  end
end
