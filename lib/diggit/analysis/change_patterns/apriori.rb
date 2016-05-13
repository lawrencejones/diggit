# encoding: utf-8
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

        def apriori_tid
          large_itemsets = large_one_itemsets
          candidate_transactions = transactions.
            map { |tid, itemsets| [tid, itemsets.map { |i| [i] }] }
          k = 1

          until large_itemsets.empty?
            k += 1
            candidate_itemsets = gen(candidate_itemsets)
            kth_candidate_transactions = Hamster::Hash[{}]

            candidate_transactions.each do |tid, itemsets|
              ct = candidate_itemsets.select do |c|
                itemsets.include?(c - [c[k]]) && itemsets.include?(c - [c[k-1]])
              end
              # PAUSE
            end
          end
        end

        # 2.1.1 Apriori Candidate Generation
        # Processes L_{k-1} to generate the set of L_{k} large itemsets.
        def gen(large_itemsets)
          candidates = gen_join(large_itemsets)
          gen_prune(large_itemsets, candidates)
        end

        # 2.1.1 Candidate Join
        # insert into Ck
        # select p.item_1, p.item_2, ..., p.item_k-1, q.item_k-1
        #   from L_{k-1} p, L_{k-1} q
        #  where p.item_1=q.item_1, ..., p.item_k-2=q.item_k-2,
        #        p.item_k-1 < q.item_k-1
        def gen_join(large_itemsets)
          large_itemsets.product(large_itemsets).map do |(p, q)|
            p.concat([q.last]) if p[0..-2] == q[0..-2] && p.last < q.last
          end.compact
        end

        # 2.1.1 Candidate Pruning
        # forall itemsets c ∈ candidates
        #   forall (k-1)-subsets s of c
        #     if s ∉ large_itemsets
        #       delete c from candidates
        def gen_prune(large_itemsets, candidates)
          k = candidates.first.size
          candidates.reject do |c|
            c.combination(k - 1).any? { |s| !large_itemsets.include?(s) }
          end
        end

        # Set of large 1-itemsets
        # Each member of this set has two fields, [itemset@[uid], support]
        def large_one_itemsets
          counter = {}.tap { |h| h.default = 0 }
          transactions.each_with_object(counter) do |(_tid, itemset), support|
            itemset.each { |uid| support[uid] += 1 }
          end.
          select { |uid, support| support >= @min_support }.
          map    { |uid, support| [[uid], support] }
        end
      end
    end
  end
end
