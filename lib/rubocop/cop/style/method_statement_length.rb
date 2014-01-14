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
          'Method is too complex. [%d/%d]'
        end

        def code_length(node)
          # total number of lines
          # lines = node.loc.expression.source.lines.to_a[1..-2] || []
          # lines.reject! { |line| irrelevant_line(line) }

          # number of statements (naive solution with no nested code of any type)
          # lines = node.children[2].children

          # number of nodes with a grandchild that is also a node (not a symbol)
          lines = count_nodes(node)

          # total number of nodes
          # lines = all_children(node)

          # lines with at least 2 nodes covering it
          # lines = lines_with_nodes(node)

          # puts node.inspect
          # puts lines
          lines
        end

        def lines_with_nodes(node)
          nodes = node.children[2].children
          count = 0
          nodes.each do |node|
            # puts node.inspect
            if node.is_a? Parser::AST::Node 
              count += lines_for_node(node)
            else
              count += 1
            end
          end
          return count
        end

        def lines_for_node(node)
          count = 0
          @lines ||= {}
          if(node.location.expression)
            begin_line = node.location.expression.line
            # I bet there is a better way to do this
            end_line = node.location.expression.instance_variable_get(:@source_buffer).decompose_position(node.location.expression.end_pos)[0]
            # puts begin_line.to_s + ":" + end_line.to_s

            count += 1 unless @lines[begin_line]

            (begin_line..end_line).each do |line_num|
              @lines[line_num] = true
            end
          end

          child_nodes = node.children.select { |c| c.is_a? Parser::AST::Node }
          # child_nodes.each do |c|
          #   count += lines_with_nodes(c)
          # end

          puts @lines.inspect
          return count
        end

        def all_children(node)
          # puts node.location.expression.inspect
          count = node.children.size
          child_nodes = node.children.select { |c| c.is_a? Parser::AST::Node }
          child_nodes.each do |c|
            count += all_children(c)
          end
          return count
        end

        def count_nodes(node)
          if(node.nil?)
            # puts "found a nil"
            return 0
          elsif(node.is_a? Parser::AST::Node)
            if node.children.empty? 
              return 0
            elsif node.type == :send
              # when calling a method, don't worry about other methods on the call chain
              # just the first one
              return 1
            elsif !has_grandchildren_nodes?(node)
              return 0
            else
              # puts "found a node with node grandchildren"
              # puts node.children.inspect
              child_counts = node.children.map { |child| count_nodes(child) }
              return 1 + child_counts.inject { |sum, count| sum + count }
            end
          else
            # puts "found a " + node.class.name
            return 0
          end
        end

        def has_grandchildren_nodes?(node)
          child_nodes = node.children.select { |c| c.is_a? Parser::AST::Node }
          grandchild_nodes = child_nodes.map { |c| c.children.select { |g| g.is_a? Parser::AST::Node }}.flatten
          return grandchild_nodes.any?
        end

        def rebuild_tree(node)
          # puts node.inspect

          # this should never be reached, hopefully
          if(!node)
            return 0
          # things that have the format (:name, (args), (begin ...))
          elsif([:def, :defs].include?(node.type))
            # puts "def called"
            return 1 + rebuild_tree(node.children[2])
          # things that have the format (:name, (lambda), (args), (begin ...))
          elsif([:block].include?(node.type))
            # puts "block called"
            return 1 + rebuild_tree(node.children[3])
          # things that have the format (:name, (begin ...))
          elsif([:begin, :kwbegin, :class, :sclass, :module].include?(node.type)) 
            # puts "begin/class/module called"
            return 1 + node.children.map { |child| rebuild_tree(child) }.inject { |sum, child| sum + child }
          # things that have the format(:if, (condition), (true code), (false code))
          # handles if, elsif, and ternaries
          elsif([:if].include?(node.type)) 
            # puts "if called"
            lines = 1
            lines += rebuild_tree(node.children[2])
            lines += rebuild_tree(node.children[3]) if node.children[3]
            return lines
          else
            # puts "standard node called"
            return 1
          end
        end
      end
    end
  end
end
