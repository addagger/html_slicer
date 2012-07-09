module HtmlSlicer
  module Mappers
    
    class Slicing # Slicing engine, generate and store resizing Map (hash)
      attr_reader :options, :map, :slice_number
      
      class Map < Hash #:nodoc:
        include HtmlSlicer::Utilities::NodeIdent

        def commit(node, number, value)
          self[node_identify(node)] ||= {}
          self[node_identify(node)].merge!(number => value)
        end
        def get(node, number)
          self[node_identify(node)] ? self[node_identify(node)][number] : nil
        end
      end

      def initialize(document, options)
        raise(TypeError, "HTML::Document expected, '#{document.class}' passed") unless document.is_a?(HTML::Document)
        raise(TypeError, "HtmlSlicer::Options expected, '#{options.class}' passed") unless options.is_a?(HtmlSlicer::Options)
        @options = options
        @map = Map.new
        @slice_number = 1
        @options.unit.is_a?(Hash) ? process_by_node!(document.root) : process_by_text!(document.root)
      end

      private

      include HtmlSlicer::Utilities::ParseNode
      include HtmlSlicer::Utilities::NodeMatchExtension

      def process_by_text!(root)
        units_count = 0
        parse(root) do |node|
          if node.is_a?(HTML::Text)
            if sliceable?(node)
              sanitize_content!(node)
              content = node.to_s
              index = 0
              begin
                while (match = content.match(@options.unit, index)) && index < content.size
                  units_count += 1
                  last_index ||= 0
                  if units_count == @options.maximum
                    units_count = 0
                    index = complete!(content, match.end(0))
                    @map.commit(node, @slice_number, [last_index, index-1])
                    last_index = index
                    limited? ? raise(Exception) : @slice_number += 1
                  else
                    index = match.end(0)
                  end
                  if units_count > 0
                    @map.commit(node, @slice_number, [last_index, -1])
                  end
                end
              rescue Exception
                break
              end
            else
              @map.commit(node, @slice_number, [0, -1])
            end
          else
            @map.commit(node, @slice_number, true)
          end
        end
      end

      def process_by_node!(root)
        units_count = 0
        parse(root) do |node|
          if node.is_a?(HTML::Text)
            @map.commit(node, @slice_number, [0, -1])
          else
            @map.commit(node, @slice_number, true)
          end
          if node.match(@options.unit) && sliceable?(node)
            units_count += 1
            if units_count == @options.maximum
              units_count = 0
              limited? ? break : @slice_number += 1
            end
          end
        end
      end

      def limited?
        @options.limit && @slice_number >= @options.limit
      end

      def sanitize_content!(node)
        content = HTML::FullSanitizer.new.sanitize(node.to_s)
        node.instance_variable_set(:@content, content)
      end

      def complete!(content, index)
        if regexp = @options.complete
          content.match(regexp, index).try(:begin, 0)||index
        else
          index
        end
      end

      def sliceable?(node)
        able_to?(node, @options)
      end

    end
  
  end
end