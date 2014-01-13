# encoding: utf-8

module Rubocop
  module Cop
    module Style
      # This cop checks if the length a method exceeds some maximum value.
      # Comment lines can optionally be ignored.
      # The maximum allowed length is configurable.
      class MethodLength < Cop
        include CheckMethods
        include CodeLength

        private

        def message
          'Method statement has too many lines. [%d/%d]'
        end

        def code_length(node)
          # total number of lines
          # lines = node.loc.expression.source.lines.to_a[1..-2] || []
          # lines.reject! { |line| irrelevant_line(line) }

          # number of statements (naive solution with no nested code of any type)
          lines = node.children[2].children

          lines = rebuild_tree(node)

          lines.size
        end

        def rebuild_tree(node)
          puts node.inspect

          # this should never be reached, hopefully
          if(!node)
            return 0
          # things that have the format (:name, (args), (begin ...))
          elsif([:def, :defs].include?(node.type))
            puts "def called"
            return 1 + rebuild_tree(node.children[2])
          # things that have the format (:name, (begin ...))
          elsif([:begin, :kwbegin, :class, :sclass, :module].include?(node.type)) 
            puts "begin/class/module called"
            return 1 + node.children.map { |child| rebuild_tree(child) }.inject { |sum, child| sum + child }
          # things that have the format(:if, (condition), (true code), (false code))
          # handles if, elsif, and ternaries
          elsif([:if].include?(node.type)) 
            puts "if called"
            lines = 1
            lines += rebuild_tree(node.children[2])
            lines += rebuild_tree(node.children[3]) if node.children.length == 4
            return lines
          else
            puts "standard node called"
            return 1
          end
        end
      end
    end
  end
end
