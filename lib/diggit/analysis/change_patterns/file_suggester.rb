require 'hamster/set'

module Diggit
  module Analysis
    module ChangePatterns
      class FileSuggester
        def initialize(frequent_itemsets, min_confidence: 0.75)
          @frequent_itemsets = frequent_itemsets
          @min_confidence = min_confidence
        end

        # Suggests files that frequently change with the given `files` with a confidence
        # of > min_confidence.
        #
        #     suggest(['report.rb']) => {
        #       'report_spec.rb' => 0.875,
        #       'spec_helper.rb' => 0.75,
        #     }
        #
        def suggest(files)
          files = Hamster::Set.new(files)

          relevant_itemsets(files).each_with_object({}) do |itemset, suggestions|
            antecedent = files.intersection(itemset[:items])
            consequent = itemset[:items].difference(antecedent)

            confidence = compute_confidence(antecedent, consequent)
            consequent.each do |file|
              suggestions[file] = [suggestions[file] || 0.0, confidence].max
            end
          end.select { |_, confidence| confidence >= min_confidence }
        end

        private

        attr_reader :frequent_itemsets, :min_confidence

        # Filter itemsets for those that contain at least one of the files, but are not
        # actual subsets of `files`.
        def relevant_itemsets(files)
          frequent_itemsets.reject do |itemset|
            itemset[:items].intersection(files).empty? || itemset[:items].subset?(files)
          end
        end

        # Finds the confidence that consequent should appear given we have antecedent.
        #
        #   Confidence({Rakefile} => {Gemfile.lock}) => 6/10 = 60%
        #
        def compute_confidence(antecedent, consequent)
          support_for(antecedent.union(consequent)).to_f / support_for(antecedent).to_f
        end

        def support_for(items)
          frequent_itemsets.find { |is| is[:items] == items }.fetch(:support)
        end
      end
    end
  end
end
