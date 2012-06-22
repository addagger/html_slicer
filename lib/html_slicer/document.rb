require 'html_slicer/makers/slicing'
require 'html_slicer/makers/resizing'

module HtmlSlicer
  
  class Document # Framework
    include HtmlSlicer::Makers
    
    attr_reader :options, :document, :slicing, :resizing
    
    delegate :root, :to => :document
    
    def initialize(env, method_name, options = {})
      @options = options
      @source = Proc.new do
        if options[:processors].present?
          HtmlSlicer::Process.iterate(env.send(method_name), options[:processors])
        else
          env.send(method_name)
        end
      end
      prepare!
    end
    
    # Resturn number of slices.
    def slice_number
      sliced? ? @slicing.slice_number : 1
    end

    def to_s(slice = 1)
      prepare! if changed?
      if sliced? && map = slicing.map[slice-1]      
        view(root, map, slicing.options.text_break)
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

    def resized?
      resizing.try(:did?)||false
    end
    
    def sliced?
      slicing.present?
    end
    
    def changed?
      @source_hash != @source.call.hash
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
        
    # Mapping the original source.
    def prepare!
      @source_hash = @source.call.hash
      @document = HTML::Document.new(@source.call)
      if options[:resize]
        @resizing = Resizing.new(document, options[:resize])
      end
      if options[:slice]
        @slicing = Slicing.new(document, options[:slice])
      end
    end
    
  end
  
end