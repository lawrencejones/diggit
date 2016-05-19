# encoding: utf-8
# rubocop:disable Style/AsciiComments, Metrics/AbcSize
require 'set'
require 'hamster/hash'

module Diggit
  module Analysis
    module ChangePatterns
      class Apriori
        def initialize(itemsets,
                       min_support: 1,
                       min_items: 1, max_items: 25)
          @min_support = min_support
          @min_confidence = min_confidence
          @database = preprocess(itemsets.select do |itemset|
            itemset.size.between?(min_items, max_items)
          end)
        end

        class Itemset
          def initialize(items, params = {})
            @items = items
            @support = params.fetch(:support, 0)
            @generators = params.fetch(:generators, Set[])
            @extensions = params.fetch(:extensions, Set[])
          end

          def to_h
            { items: @items, support: @support }
          end

          attr_reader :items, :generators, :extensions
          attr_accessor :support
        end

        attr_reader :min_support, :min_confidence, :database

        # 2.2 AprioriTid
        # Returns [[itemset, support], ...]
        def frequent_itemsets
          k = 2
          l = [nil, large_one_itemsets]

          # Transform itemsets into a mapping of tid to {Itemset}
          tid_itemsets = itemsets.map do |tid, items|
            [tid, items.map do |item|
              l[k - 1].find { |itemset| itemset.items[0] == item }
            end.compact.to_set]
          end

          until l[k - 1].empty?
            cks = gen(l[k - 1])
            kth_tid_itemsets = Hamster::Hash[{}]

            tid_itemsets.each do |tid, set_of_itemsets|
              # Find candidate itemsets in ck contained in the transaction
              cts = set_of_itemsets.flat_map do |ck_1|
                ck_1.extensions.select do |ck|
                  ck.generators.subset?(set_of_itemsets)
                end
              end.to_set

              # Register the support for each transaction candidate
              cts.each { |ct| ct.support += 1 }

              # Update the transaction candidate list for the next k value
              kth_tid_itemsets = kth_tid_itemsets.merge(tid => cts) unless cts.empty?
            end

            l[k] = cks.select { |candidate| candidate.support >= min_support }
            tid_itemsets = kth_tid_itemsets.map do |tid, cts|
              [tid, cts.select { |c| l[k].include?(c) }.to_set]
            end

            k += 1
          end

          l.flatten.compact.map(&:to_h)
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
          gen_prune(lk, candidates).each do |candidate|
            candidate.generators.each { |g| g.extensions.add(candidate) }
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
          lk.product(lk).map do |(p, q)|
            if p.items[0..-2] == q.items[0..-2] && p.items.last < q.items.last
              Itemset.new([*p.items, q.items.last], generators: Set[p, q])
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

          lk_itemsets = lk.map(&:items).to_set
          k = candidates.first.items.size
          candidates.reject do |candidate|
            candidate.items.combination(k - 1).
              any? { |subset| !lk_itemsets.include?(subset) }
          end
        end

        # Set of large 1-itemsets
        # Each member of this set has two fields, [itemset@[uid], support]
        def large_one_itemsets
          database.each_with_object(counter) do |(_, itemset), support|
            itemset.each { |item| support[item] += 1 }
          end.
          select { |item, support| support >= @min_support }.
          map    { |item, support| Itemset.new([item], support: support) }
        end

        private

        def preprocess(itemsets)
          Hamster::Hash[itemsets.each_with_index.map { |itemset, i| [i, itemset] }]
        end

        def counter
          {}.tap { |h| h.default = 0 }
        end
      end
    end
  end
end
