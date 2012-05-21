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

    def width(node)
      values = []
      if block_given?
        node.attributes["width"] = yield
      else
        values << absolute_resolution(node.attributes["width"])
      end
      if style = node.attributes["style"]
        style.gsub!(/width:\s+\d+px;/) do |t|
          t.gsub(/\d+/) do |w|
            if block_given?
              yield
            else
              values << w.to_i
              w
            end
          end
        end
      end
      values.compact.min
    end

    def height(node)
      values = []
      if block_given?
        node.attributes["height"] = yield
      else
        values << absolute_resolution(node.attributes["height"])
      end
      if style = node.attributes["style"]
        style.gsub!(/height:\s+\d+px;/) do |t|
          t.gsub(/\d+/) do |h|
            if block_given?
              yield
            else
              values << h.to_i
              h
            end
          end
        end
      end
      values.compact.min
    end

    def resize!(node)
      target_width = node.parent.is_a?(HTML::Tag) ? width(node.parent)||@options.width : nil
      if target_width.present? && node_width = width(node)
        node_height = height(node)
        if node_width > target_width
          ratio = node_width.to_f/target_width
          width(node) { target_width.to_s }
          height(node) { (node_height/ratio).round.to_s } if node_height
        end
      end
    end

    def absolute_resolution(value)
      (value.present? && value.last != "%") ? value.to_i : nil
    end

  end
  
end