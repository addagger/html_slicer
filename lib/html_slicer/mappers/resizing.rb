module HtmlSlicer
  module Mappers
    
    class Resizing # Resizing engine, generate and store slicing Map (hash)
      attr_reader :options, :map

      class Map < Hash #:nodoc:        
        def commit(node, width, height)
          self[node.path] = [width, height]
        end
        def width(node)
          self[node.path].try(:first)
        end
        def height(node)
          self[node.path].try(:last)
        end
      end

      def initialize(fragment, options)
        raise(TypeError, "Nokogiri::HTML::DocumentFragment expected, '#{document.class}' passed") unless document.try(:fragment?)
        raise(TypeError, "HtmlSlicer::Options expected, '#{options.class}' passed") unless options.is_a?(HtmlSlicer::Options)
        @options = options
        @map = Map.new
        process!(fragment)
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

      def process!(fragment)
        parse(fragment) do |node|
          if node.try(:element?) && resizeable?(node)
            target_width = node.try(:element?) ? @map.width(node.parent)||@options.width : @options.width
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
          style.content.gsub!(/width:\s+\d+(?=px);/) do |w|
            if block_given?
              yield
            else
              values << w.to_i
              w
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
          style.content.gsub!(/height:\s+\d+(?=px);/) do |h|
            if block_given?
              yield
            else
              values << h.to_i
              h
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