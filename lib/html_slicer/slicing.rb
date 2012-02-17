module HtmlSlicer
      
  class Slicing
    
    class Matrix
      def initialize
        @map = {}
      end

      def assign(node, index = true)
        @map[node.object_id] = index
      end

      def show
        @map
      end

      def to_s(node)
        view(node)
      end

      def inspect
        @map
      end

      def method_missing(*args, &block)
        @map.send(*args, &block)
      end

      private

      # Return a textual representation of the node including all children assigned to a +map+.
      def view(node)
        case node
        when HTML::Tag then
          children_view = node.children.collect {|child| view(child)}.compact.join
          if @map[node.object_id] || children_view.present?
            if node.closing == :close
              "</#{node.name}>"
            else
              s = "<#{node.name}"
              node.attributes.each do |k,v|
                s << " #{k}"
                s << "=\"#{v}\"" if String === v
              end
              s << " /" if node.closing == :self
              s << ">"
              s += children_view
              s << "</#{node.name}>" if node.closing != :self && !node.children.empty?
              s
            end
          end
        when HTML::Text then
          node.content[@map[node.object_id]] if @map[node.object_id]
        when HTML::CDATA then
          node.to_s
        when HTML::Node then
          node.children.collect {|child| view(child)}.compact.join
        end
      end

    end
  
    attr_reader :document, :options, :slices, :slice_options, :resize_options, :current_slice

    delegate :root, :to => :document
    
    def initialize(content, options = {})
      raise(TypeError, "String object expected, '#{content.class}' passed") unless content.is_a?(String)
      @options = options
      @slice_options = SliceOptions.new(options[:slice]) if options[:slice]
      @resize_options = ResizeOptions.new(options[:resize]) if options[:resize]
      @slices = [Matrix.new]
      @current_slice = 1
      @document = HTML::Document.new(HtmlSlicer::Process.iterate(content, options[:processors]))
      if slice_options
        case slice_options.unit
        when Regexp then slice_document_by_text!(slice_options.unit)
        when String then slice_document_by_text!(/#{slice_options.unit}/)
        when :char then slice_document_by_text!(/&#?\w+;|\S/)
        when Hash then slice_document_by_node!(slice_options.unit)
        end
      end
      if resize_options
        resize_document!
      end
    end
    
    # Resturn number of slices.
    def slice_number
      @slices.size
    end
    
    # General slicing method. Passing the argument changes the slice.
    def slice!(slice = nil)
      raise(Exception, "Slicing options unavailable!") unless sliced?
      if slice.present?
        if slice.to_i.in?(1..slice_number)
          @current_slice = slice.to_i
        else
          raise(ArgumentError, "Slice number must be Fixnum in (1..#{slice_number}). #{slice.inspect} passed.")
        end
      end
      self
    end
    
    # Textual representation according to a current slice.
    def to_s
      sliced? ? @slices[current_slice-1].to_s(root) : root
    end
    
    def inspect
      to_s
    end
    
    def method_missing(*args, &block)
      to_s.send(*args, &block)
    end
    
    def sliced?
      @sliced||false
    end
    
    def resized?
      @resized||false
    end
    
    def last_slice?
      current_slice == slice_number
    end
    
    private
  
    include HtmlSlicer::Utilities::NodeMatchExtension
  
    def slice_document_by_text!(unit)
      units_count = 0
      parse(root) do |node|
        if node.is_a?(HTML::Text)
          if sliceable?(node)
            sanitize_content!(node)
            content = node.to_s
            index = 0
            begin
              while (match = content.match(unit, index)) && index < content.size
                units_count += 1
                last_index ||= 0
                if units_count == slice_options.maximum
                  units_count = 0
                  index = complete!(content, match.end(0))
                  @slices.last.assign(node, Range.new(last_index, index-1))
                  last_index = index
                  limited? ? raise(Exception) : @slices << Matrix.new
                else
                  index = match.end(0)
                end
                if units_count > 0
                  @slices.last.assign(node, Range.new(last_index, -1))
                end
              end
            rescue Exception
              break
            end
          else
            @slices.last.assign(node, Range.new(0, -1))
          end
        else
          @slices.last.assign(node, true)
        end
      end
      @sliced = true
    end
    
    def slice_document_by_node!(unit)
      units_count = 0
      parse(root) do |node|
        if node.is_a?(HTML::Text)
          @slices.last.assign(node, Range.new(0, -1))
        else
          @slices.last.assign(node, true)
        end
        if node.match(unit) && sliceable?(node)
          units_count += 1
          if units_count == slice_options.maximum
            units_count = 0
            limited? ? break : @slices << Matrix.new
          end
        end
      end
      @sliced = true
    end
    
    def resize_document!
      parse(root) do |node|
        resize!(node) if node.is_a?(HTML::Tag) && resizeable?(node)
      end
      @resized = true
    end
  
    def complete!(content, index)
      if regexp = slice_options.complete
        content.match(regexp, index).try(:begin, 0)||index
      else
        index
      end
    end
  
    def parse(node, &block)
      node.children.each do |node|
        yield node if block_given?
        parse(node, &block) if node.is_a?(HTML::Tag)
      end
    end
    
    def limited?
      slice_options.limit && @slice_number >= slice_options.limit
    end
  
    def sliceable?(node)
      able_to?(node, slice_options)
    end
  
    def resizeable?(node)
      able_to?(node, resize_options)
    end
  
    def resize!(node)
      parent_width = node.parent.is_a?(HTML::Tag) ? absolute_resolution(node.parent.attributes["width"]) : nil
      target_width = parent_width.present? ? parent_width.to_i : resize_options.width
      if target_width.present? && node_width = absolute_resolution(node.attributes["width"])
        node_height = absolute_resolution(node.attributes["height"])
        if node_width > target_width
          ratio = node_width.to_f/target_width
          node.attributes["width"] = target_width.to_s
          node.attributes["height"] = (node_height/ratio).round.to_s if node_height
        end
      end
    end
  
    def sanitize_content!(node)
      content = HTML::FullSanitizer.new.sanitize(node.to_s)
      node.instance_variable_set(:@content, content)
    end
  
    def absolute_resolution(value)
      (value.present? && value.last != "%") ? value.to_i : nil
    end
  
  end
  
end