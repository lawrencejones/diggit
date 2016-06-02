require 'hamster'
require 'timeout'
require_relative '../../logger'

module Diggit
  module Analysis
    module ChangePatterns
      # Discovers appropriate minimum support parameter for given changesets.
      #
      # Selects the minimum support that yields results in less than TIMEOUT
      # seconds or that includes FILES_INCLUDED_THRESHOLD of the given files in
      # the repo.
      class MinSupportFinder
        TIMEOUT = 60.seconds
        FILES_INCLUDED_THRESHOLD = 0.3
        INITIAL_SUPPORT = 20

        include InstanceLogger

        def initialize(algorithm, changesets, current_files)
          @algorithm = algorithm
          @changesets = changesets
          @current_files = Hamster::SortedSet.new(current_files)
        end

        def support
          @support ||= generate_support
        end

        private

        attr_reader :algorithm, :changesets, :current_files

        def generate_support
          INITIAL_SUPPORT.downto(2).each do |min_support|
            files_included = benchmark(min_support)

            return min_support + 1 if files_included.nil? # timed out
            return min_support if files_included > FILES_INCLUDED_THRESHOLD
          end

          2
        end

        def benchmark(min_support)
          info { "Benchmarking min_support=#{min_support}..." }
          frequent_itemsets = Timeout.timeout(10.seconds) do
            algorithm.
              new(changesets, min_support: min_support).
              frequent_itemsets
          end
          info { "Found #{frequent_itemsets.size} frequent itemsets!" }

          ratio_files_included(frequent_itemsets)
        rescue Timeout::Error
          info { "Timeout for min_support=#{min_support}!" }
          nil
        end

        def ratio_files_included(itemsets)
          files_in_patterns = itemsets.map { |p| p[:items] }.inject(:+)
          return 0.0 if files_in_patterns.nil?

          current_files.intersection(files_in_patterns).size / current_files.size.to_f
        end
      end
    end
  end
end
