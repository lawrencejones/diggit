# encoding: utf-8
# rubocop:disable Style/AsciiComments, Metrics/AbcSize
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
              ct = ck.select { |candidate| t & candidate[:items] == candidate[:items] }
              ct.each do |candidate|
                candidate[:support] += 1
              end
            end

            l[k] = ck.select { |candidate| candidate[:support] >= min_support }
            k += 1
          end

          l.flatten.compact.map { |itemset| itemset.slice(:items, :support) }
        end

        # 2.2 AprioriTid
        # Returns [[itemset, support], ...]
        def apriori_tid
          k = 2
          l = [nil, large_one_itemsets]

          # Transform transactions into a mapping of tid to {id}, where id is an index
          # into l[k-1] itemsets.
          tid_itemsets = transactions.map do |tid, items|
            [tid, items.map do |item|
              l[k - 1].index { |itemset| itemset[:items][0] == item }
            end.compact.to_set]
          end

          until l[k - 1].empty?
            cks = gen(l[k - 1])
            kth_tid_itemsets = Hamster::Hash[{}]

            tid_itemsets.each do |tid, itemset_indexes|
              # Find candidate itemsets in ck contained in the transaction
              cts = itemset_indexes.flat_map do |itemset_index|
                ck_1 = l[k - 1][itemset_index]
                ck_1[:extensions].map do |ck_index|
                  ck = cks[ck_index]
                  ck[:generators].subset?(itemset_indexes) ? ck : nil
                end
              end.compact.to_set

              # Register the support for each transaction candidate
              cts.each { |ct| ct[:support] += 1 }

              # Update the transaction candidate list for the next k value
              kth_tid_itemsets = kth_tid_itemsets.merge(tid => cts) unless cts.empty?
            end

            l[k] = cks.select { |candidate| candidate[:support] >= min_support }
            tid_itemsets = kth_tid_itemsets.map do |tid, cts|
              [tid, cts.map { |c| l[k].index(c) }.compact.to_set]
            end

            k += 1
          end

          l.flatten.compact.map { |itemset| itemset.slice(:items, :support) }
        end

        # 2.1.1 Apriori Candidate Generation
        # Processes L_{k-1} to generate the set of L_{k} large itemsets.
        #
        #   [[items: [item, ...], support: 0, generators: Set, extensions: Set], ...]
        #
        # Sets extensions of lk candidates, and generators of the new k+1 candidates.
        def gen(lk)
          candidates = gen_join(lk)
          # Prune, then add index of new candidates to extensions of it's generators
          gen_prune(lk, candidates).each_with_index do |j, jid|
            j[:generators].each { |gid| lk[gid][:extensions].add(jid) }
          end
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
        # Sets the generators field of every new candidate, but cannot set extensions
        # until pruning has taken place (to maintain the indexes)
        def gen_join(lk)
          lk.each_with_index.flat_map do |p, pid|
            lk.each_with_index.map do |q, qid|
              if p[:items][0..-2] == q[:items][0..-2] && p[:items].last < q[:items].last
                { items: [*p[:items], q[:items].last], support: 0,
                  generators: Set[pid, qid], extensions: Set[] }
              end
            end
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
        def gen_prune(lk, candidates)
          return [] if candidates.empty?

          lk_itemsets = lk.map { |c| c[:items] }
          k = candidates.first[:items].size
          candidates.reject do |c|
            c[:items].combination(k - 1).any? { |s| !lk_itemsets.include?(s) }
          end
        end

        # Set of large 1-itemsets
        # Each member of this set has two fields, [itemset@[uid], support]
        def large_one_itemsets
          transactions.each_with_object(counter) do |(_, itemset), support|
            itemset.each { |item| support[item] += 1 }
          end.
          select { |item, support| support >= @min_support }.
          map   do |item, support|
            { items: [item], support: support,
              generators: Set.new, extensions: Set.new }
          end
        end

        private

        def counter
          {}.tap { |h| h.default = 0 }
        end
      end
    end
  end
end
