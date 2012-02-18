module HtmlSlicer
  
  class Resizing # Resizing engine
    attr_reader :options
    
    def initialize(document, options = {})
      raise(TypeError, "HTML::Document expected, '#{document.class}' passed") unless document.is_a?(HTML::Document)
      @options = ResizeOptions.new(options)
      resize_document!(document.root)
    end

    private

    include HtmlSlicer::Utilities::ParseNode
    include HtmlSlicer::Utilities::NodeMatchExtension

    def resize_document!(root)
      parse(root) do |node|
        resize!(node) if node.is_a?(HTML::Tag) && resizeable?(node)
      end
    end

    def resizeable?(node)
      able_to?(node, @options)
    end

    def resize!(node)
      parent_width = node.parent.is_a?(HTML::Tag) ? absolute_resolution(node.parent.attributes["width"]) : nil
      target_width = parent_width.present? ? parent_width.to_i : @options.width
      if target_width.present? && node_width = absolute_resolution(node.attributes["width"])
        node_height = absolute_resolution(node.attributes["height"])
        if node_width > target_width
          ratio = node_width.to_f/target_width
          node.attributes["width"] = target_width.to_s
          node.attributes["height"] = (node_height/ratio).round.to_s if node_height
        end
      end
    end

    def absolute_resolution(value)
      (value.present? && value.last != "%") ? value.to_i : nil
    end

  end
  
end