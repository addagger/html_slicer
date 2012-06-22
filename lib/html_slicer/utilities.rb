module HtmlSlicer
  module Utilities

    module ParseNode
      def parse(node, &block)
        node.children.each do |node|
          yield node if block_given?
          parse(node, &block) if node.is_a?(HTML::Tag)
        end
      end
    end

    module Deepcopy
      # Return the 'deep' brand new copy of Hash or Array. All nested hashes/arrays rebuilded at the same way.
      def deepcopy(object)
        array_copy = Proc.new do |a|
          duplicate = Array.new
          a.each do |value|
            duplicate << case value
            when Hash then hash_copy.call(value)
            when Array then array_copy.call(value)
            else value
            end
          end
          duplicate
        end
        hash_copy = Proc.new do |h|
          duplicate = Hash.new
          h.each do |key, value|
            duplicate[key] = case value
            when Hash then hash_copy.call(value)
            when Array then array_copy.call(value)
            else value
            end
          end
          duplicate
        end
        case object
        when Hash then hash_copy.call(object)
        when Array then array_copy.call(object)
        else object
        end
      end
    end

    module HashupArray
      # Return a nested Hash object from Array's elements sequence, where elements used as names of +hash+ keys.
      # The last element of array would be the last nested value.
      #
      # === Example:
      #   
      #   hashup([:vehicle, :car, :ford, :mustang, "2 please"])
      #
      #   #=> {:vehicle=>{:car=>{:ford=>{:mustang=>"2 please"}}}}
      def hashup(array)
        raise(TypeError, "Array expected!") unless array.is_a?(Array)
        raise(Exception, "At least 2 elements needed!") if array.size < 2
        value = array.delete_at(-1)
        hash = {}
        index = 0
        last_hash = hash
        while index < array.size
          last_hash = last_hash[array.at(index)] = (index + 1 == array.size) ? value : {}
          index += 1
        end
        hash
      end      
    end
    
    module NestedMergeHash
      include Deepcopy

      # Return the merged Hash with another +hash+, where the possible child hashes are also merged.
      #
      # === Example:
      # 
      #   h1 = {:breakfast => {:eggs => 2, :bread => 1}, :lunch => {:steak => 1, :salad => 1}}
      #   h2 = {:breakfast => {:coffee => :espresso, :juice => 1}, :lunch => {:tea => 2}, :dinner => :none}
      #   nested_merge(h1, h2)
      #   #=> {:breakfast=>{:eggs=>2, :bread=>1, :coffee=>:espresso, :juice=>1}, :lunch=>{:steak=>1, :salad=>1, :tea=>2}, :dinner=>:none}
      #
      def nested_merge(hash, other_hash = {})
        raise(TypeError, "Hash expected!") unless hash.is_a?(Hash)
        a = Proc.new do |original, change|
          change.each do |key, value|
            if !original.has_key?(key) || !original[key].is_a?(Hash)
              original[key] = value
            elsif original[key].is_a?(Hash) && value.is_a?(Hash)
              a.call(original[key], value)
            end
          end
          original
        end
        a.call(deepcopy(hash), other_hash)
      end

      # .nested_merge replaces the source hash.
      def nested_merge!(hash, other_hash = {})
        hash.replace(nested_merge(hash, other_hash = {}))
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