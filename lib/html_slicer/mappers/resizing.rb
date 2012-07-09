module HtmlSlicer
  module Mappers
    
    class Resizing # Resizing engine, generate and store slicing Map (hash)
      attr_reader :options, :map

      class Map < Hash #:nodoc:
        include HtmlSlicer::Utilities::NodeIdent
        
        def commit(node, width, height)
          self[node_identify(node)] = [width, height]
        end
        def width(node)
          self[node_identify(node)].try(:first)
        end
        def height(node)
          self[node_identify(node)].try(:last)
        end
      end    

      def initialize(document, options)
        raise(TypeError, "HTML::Document expected, '#{document.class}' passed") unless document.is_a?(HTML::Document)
        raise(TypeError, "HtmlSlicer::Options expected, '#{options.class}' passed") unless options.is_a?(HtmlSlicer::Options)
        @options = options
        @map = Map.new
        process!(document.root)
      end

      def resize_node(node)
        if w = @map.width(node)
          width(node) { w.to_s }
        end
        if h = @map.height(node)
          height(node) { h.to_s }
        end
      end

      private

      include HtmlSlicer::Utilities::ParseNode
      include HtmlSlicer::Utilities::NodeMatchExtension

      def process!(root)
        parse(root) do |node|
          if node.is_a?(HTML::Tag) && resizeable?(node)
            target_width = node.parent.is_a?(HTML::Tag) ? @map.width(node.parent)||@options.width : @options.width
            if target_width.present? && node_width = width(node)
              node_height = height(node)
              if node_width > target_width
                ratio = node_width.to_f/target_width
                @map.commit(node, target_width, node_height ? (node_height/ratio).round : nil)
              end
            end
          end
        end
      end

      def resizeable?(node)
        able_to?(node, @options)
      end

      def width(node)
        values = []
        if block_given? && node.attributes.has_key?("width")
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
        if block_given? && node.attributes.has_key?("height")
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

      def absolute_resolution(value)
        (value.present? && value.last != "%") ? value.to_i : nil
      end

    end
  
  end
end