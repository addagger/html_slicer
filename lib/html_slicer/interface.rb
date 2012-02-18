module HtmlSlicer
  
  class Interface # General accessor instance
    attr_reader :document, :options, :current_slice

    delegate :root, :to => :document
    
    def initialize(content, options = {})
      raise(TypeError, "String object expected, '#{content.class}' passed") unless content.is_a?(String)
      @options = options
      @current_slice = 1
      @document = HTML::Document.new(HtmlSlicer::Process.iterate(content, options[:processors]))
      if @options[:slice]
        @slicing = Slicing.new(document, @options[:slice])
      end
      if @options[:resize]
        @resizing = Resizing.new(document, @options[:resize])
      end
    end

    # Resturn number of slices.
    def slice_number
      sliced? ? @slicing.slice_number : 1
    end

    # General slicing method. Passing the argument changes the slice.
    def slice!(slice = nil)
      raise(Exception, "Slicing unavailable!") unless sliced?
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
      if sliced? && map = @slicing.map[current_slice-1]
        view(root, map, @slicing.options.text_break)
      else
        root
      end
    end
    
    def inspect
      to_s
    end
    
    def method_missing(*args, &block)
      to_s.send(*args, &block)
    end
    
    def sliced?
      @slicing.present?
    end
    
    def resized?
      @resizing.present?
    end
    
    # Return the current slice is a last or not?
    def last_slice?
      current_slice == slice_number
    end
    
    private

    # Return a textual representation of the node including all children assigned to a +map+.
    def view(node, map = {}, text_break = nil)
      case node
      when HTML::Tag then
        children_view = node.children.collect {|child| view(child, map, text_break)}.compact.join
        if map[node.object_id] || children_view.present?
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
        if range = map[node.object_id]
          "#{node.content[range]}#{text_break unless range.last == -1}"
        end
      when HTML::CDATA then
        node.to_s
      when HTML::Node then
        node.children.collect {|child| view(child, map, text_break)}.compact.join
      end
    end

  end
  
end