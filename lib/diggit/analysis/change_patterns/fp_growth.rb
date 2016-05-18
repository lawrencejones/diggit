require 'set'
require 'hamster/hash'

module Diggit
  module Analysis
    module ChangePatterns
      class FpGrowth
        def initialize(itemsets,
                       min_support: 1,
                       min_items: 2,
                       max_items: 10)
          @min_support = min_support
          @database = preprocess(itemsets.select do |itemset|
            itemset.size.between?(min_items, max_items)
          end)
        end

        attr_reader :database, :min_support

        class Node
          def initialize(item, count = 0)
            @item = item
            @count = count
          end

          attr_reader :item
          attr_accessor :count, :parent, :succ, :aux

          # Provides enumerator interface for accessing elements from a linked list.
          # Requires benchmarking, but should in theory allow lazy enumeration through the
          # list elements.
          def self.enum_for_linked_list(accessor:, method_alias:)
            define_method(method_alias) do |&block|
              return to_enum(method_alias) unless block

              next_element = send(accessor)
              until next_element.nil?
                block.call(next_element)
                next_element = next_element.send(accessor)
              end
            end
          end

          enum_for_linked_list(accessor: :succ, method_alias: :nodes)
          enum_for_linked_list(accessor: :parent, method_alias: :parents)
        end

        class Tree
          def initialize
            @heads = {}
          end

          attr_accessor :heads

          def add_node(node)
            head = @heads[node.item] ||= Node.new(node.item)
            head.count += node.count

            head = head.succ until head.succ.nil?
            head.succ = node
          end
        end

        def initial_tree
          build_tree(database)
        end

        # Recurse through the initial tree to identify the frequent itemsets that appear
        # with > min_support.
        def frequent_itemsets(tree = initial_tree,
                              itemsets = Set.new,
                              prefix = Hamster::Set[])
          tree.heads.
            reject { |item, head| head.count < min_support }.
            each do  |item, head|
              itemset = { items: prefix.add(item), support: head.count }
              itemsets.add(itemset)
              frequent_itemsets(project_tree(tree, item), itemsets, itemset[:items])
            end

          itemsets
        end

        private

        # 2.1 Preprocessing
        #
        # Prepares an unsorted, unfiltered list of itemsets for seeding the algorithm.
        # This involves filtering items without min_support, and sorting each itemset
        # in descending lexicographical order.
        #
        #   preprocess([[:a, :b, :c], [:a, :b]])
        #   => [[:c, :b], [:b]]
        #
        def preprocess(itemsets)
          counts = frequency_count(itemsets).
            reject { |_, count| count < min_support }

          itemsets.map do |itemset|
            itemset.
              select  { |item| counts.key?(item) }.
              sort_by { |item| -counts[item] }
          end
        end

        # 3.1 Building the initial FP-Tree
        #
        # Generates the initial FP tree from the database, by recursively splitting the
        # database for each new node layer.
        def build_tree(database, k = 0, tree = Tree.new, parent = nil)
          database.group_by { |itemset| itemset[k] }.each do |item, itemsets|
            node = Node.new(item, itemsets.count)
            node.parent = parent
            tree.add_node(node)

            filtered_database = itemsets.select { |itemset| itemset.size > k + 1 }
            build_tree(filtered_database, k + 1, tree, node)
          end

          tree
        end

        # 4.1 Projecting an FP-Tree
        # Projects by removing the given item and generating a new tree, of all the
        # consequent frequency counts.
        def project_tree(tree, item)
          # Find first node for the prefix
          prefix_node = tree.heads.fetch(item)

          # Create auxiliary node clones with projected counts, setting aux node parents
          # to be non-aux parents
          prefix_node.nodes.each do |node|
            node.parents.reduce(node.clone) do |aux_child, parent|
              parent.aux ||= Node.new(parent.item)
              parent.aux.count += aux_child.count
              aux_child.parent = parent.aux
            end
          end

          # Detach all auxiliary nodes into a fresh FP-Tree
          prefix_node.nodes.each_with_object(Tree.new) do |node, projection|
            node.parents.each do |parent|
              next if parent.aux.nil?
              projection.add_node(parent.aux)
              parent.aux = nil
            end
          end
        end

        def frequency_count(itemsets)
          itemsets.each_with_object(counter) do |items, counter|
            items.each { |item| counter[item] += 1 }
          end
        end

        def counter
          {}.tap { |h| h.default = 0 }
        end
      end
    end
  end
end
