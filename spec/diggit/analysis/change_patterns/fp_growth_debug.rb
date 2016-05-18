require 'diggit/analysis/change_patterns/fp_growth'

module Diggit
  module Analysis
    module ChangePatterns
      class FpGrowth
        class Node
          def to_s
            "[#{item}:#{count}]" # [d:5]
          end
        end

        class Tree
          # Generate human readable FPTree, an list of [head, [node]] pairs where each
          # head prints as `[item:count]` string, and each node is formatted with given
          # formatter.
          #
          # Example with default `format_node_with_parent` formatter...
          #
          #   [
          #     [ '[d:8]', ['[d:8]'] ],
          #     [ '[b:7]', ['[b:5]->d[0]', '[b:2]'],
          #     ...,
          #   ]
          #
          def inspect(node_formatter_method = :node_with_parent_index)
            formatter = send(:"format_#{node_formatter_method}")
            heads.
              sort_by { |item, head| [-head.count, head.nodes.to_a.size] }.
              map do |item, head|
                [head.to_s, head.nodes.map(&formatter).compact]
              end
          end

          # Displays the index of the nodes parent.
          # `[item:count]->parent[index]`
          def format_node_with_parent_index
            proc do |node|
              next(node.to_s) if node.parent.nil?
              parent_index = heads[node.parent.item].nodes.to_a.index(node.parent)
              "#{node}->#{node.parent.item}[#{parent_index}]"
            end
          end

          # Displays auxiliary node if present
          # `[item:count]#[aux:count]`
          def format_node_with_aux
            proc do |node|
              [node, node.aux].compact.map(&:to_s).join('#')
            end
          end
        end
      end
    end
  end
end
