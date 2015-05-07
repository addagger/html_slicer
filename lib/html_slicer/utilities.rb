module HtmlSlicer
  module Utilities

    module ParseNode
      def parse(node, &block)
        node.children.each do |node|
          yield node if block_given?
          if node.is_a?(::HTML::Tag)
            parse(node, &block)
          end
        end
      end
    end

    module NodeIdent
      def node_identify(node)
        [node.line, node.position]
      end
    end
    
    module NodeMatchExtension
    
      # Checking if node is included in +:only+ parameter and/or excluded of +:except+ parameeter.
      def able_to?(node, options)
        if options.only.present?
          general_match(node, options.only)
        elsif options.except.present?
          !general_match(node, options.except)
        else
          true
        end
      end
    
      # Checking if node is a member of other node's tree. Accepts +hashes+ as conditions.
      # Returns +true+ if node or it's parent matches at least one condition, or +false+ otherwise.
      def general_match(node, hashes = [])
        conditions = Array.wrap(hashes)
        while node
          break true if conditions.each {|condition| break true if node.match(condition)} == true
          node = node.parent
        end||false
      end
    
    end
    
  end
end