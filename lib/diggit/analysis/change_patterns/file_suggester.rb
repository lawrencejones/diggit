require 'hamster/set'

module Diggit
  module Analysis
    module ChangePatterns
      class FileSuggester
        def initialize(frequent_itemsets, min_confidence: 0.75)
          @frequent_itemsets = frequent_itemsets
          @min_confidence = min_confidence
          @itemset_support = frequent_itemsets.map do |frequent_itemset|
            [frequent_itemset[:items].hash, frequent_itemset[:support]]
          end.to_h
        end

        # Suggests files that frequently change with the given `files` with a confidence
        # of > min_confidence.
        #
        #     suggest(['report.rb']) => {
        #       'report_spec.rb' => { confidence: 0.875, antecedent: Set[...] },
        #       'spec_helper.rb' => { confidence: 0.75, antecedent: Set[...] },
        #     }
        #
        def suggest(files)
          files = Hamster::SortedSet.new(files)

          relevant_itemsets(files).each_with_object({}) do |itemset, suggestions|
            antecedent = files.intersection(itemset[:items])
            consequent = itemset[:items].difference(antecedent)

            confidence = compute_confidence(antecedent, consequent)
            next unless confidence >= min_confidence

            consequent.each do |file|
              next if suggestions.fetch(file, confidence: 0.0)[:confidence] > confidence
              suggestions[file] = { confidence: confidence, antecedent: antecedent }
            end
          end
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
          @itemset_support[items.hash] || 0
        end
      end
    end
  end
end
