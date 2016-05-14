# encoding: utf-8
# rubocop:disable Style/AsciiComments
require 'set'
require 'hamster/hash'

module Diggit
  module Analysis
    module ChangePatterns
      class Apriori
        def initialize(transactions,
                       min_support: 1,
                       min_confidence: 0.75,
                       min_items: 2, max_items: 50)
          @min_support = min_support
          @min_confidence = min_confidence
          @transactions = Hamster::Hash[transactions].
            select { |tid, itemset| itemset.size.between?(min_items, max_items) }
        end

        attr_reader :min_support, :min_confidence, :transactions

        # 2.1 Apriori Standard
        # Returns [[itemset, support], ...]
        def apriori
          # [[[uid], support], ...]
          l = [nil, large_one_itemsets]
          k = 2

          until l[k - 1].empty?
            ck = gen(l[k - 1])
            transactions.each do |tid, t|
              # Candidates contained in transaction t
              ct = ck.select { |(itemset)| t & itemset == itemset }
              ct.each do |candidate|
                candidate[1] += 1
              end
            end

            l[k] = ck.select { |(_, count)| count >= min_support }
            k += 1
          end

          l.compact.inject(:+)
        end

        # 2.1.1 Apriori Candidate Generation
        # Processes L_{k-1} to generate the set of L_{k} large itemsets.
        #
        #   [[itemset, count], ...]
        #
        def gen(lk)
          large_itemsets = lk.map(&:first)
          candidates = gen_join(large_itemsets)
          gen_prune(large_itemsets, candidates).map { |itemset| [itemset, 0] }
        end

        # 2.1.1 Candidate Join
        # insert into Ck
        # select p.item_1, p.item_2, ..., p.item_k-1, q.item_k-1
        #   from L_{k-1} p, L_{k-1} q
        #  where p.item_1=q.item_1, ..., p.item_k-2=q.item_k-2,
        #        p.item_k-1 < q.item_k-1
        #
        #   [itemset, ...]
        #
        def gen_join(large_itemsets)
          large_itemsets.product(large_itemsets).map do |(p, q)|
            [*p, q.last] if p[0..-2] == q[0..-2] && p.last < q.last
          end.compact
        end

        # 2.1.1 Candidate Pruning
        # forall itemsets c ∈ candidates
        #   forall (k-1)-subsets s of c
        #     if s ∉ large_itemsets
        #       delete c from candidates
        #
        #   [itemset, ...]
        #
        def gen_prune(large_itemsets, candidates)
          return [] if candidates.empty?

          k = candidates.first.size
          candidates.reject do |c|
            c.combination(k - 1).any? { |s| !large_itemsets.include?(s) }
          end
        end

        # Set of large 1-itemsets
        # Each member of this set has two fields, [itemset@[uid], support]
        def large_one_itemsets
          transactions.each_with_object(counter) do |(_, itemset), support|
            itemset.each { |uid| support[uid] += 1 }
          end.
          select { |uid, support| support >= @min_support }.
          map    { |uid, support| [[uid], support] }
        end

        private

        def counter
          {}.tap { |h| h.default = 0 }
        end
      end
    end
  end
end
