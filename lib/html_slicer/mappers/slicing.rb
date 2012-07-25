module HtmlSlicer
  module Mappers
    
    class Slicing # Slicing engine, generate and store resizing Map (hash)
      attr_reader :options, :map, :slice_number
      
      class Map < Hash #:nodoc:
        include HtmlSlicer::Utilities::NodeIdent

        def commit(node, number, value)
          value = true if value == [0, -1]
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
          if node.is_a?(HTML::Text) && sliceable?(node)
            sanitize_content!(node)
            content = node.to_s
            begin
              start_index = 0
              last_index = 0
              content.scan(@options.unit) do
                if $~.begin(0) >= start_index
                  units_count += 1
                  index = $~.end(0)
                  if units_count == @options.maximum
                    units_count = 0
                    if complete_regexp = @options.complete
                      index = content.match(complete_regexp, index).try(:begin, 0)||index
                      start_index = index
                    end
                    @map.commit(node, @slice_number, [last_index, index-1])
                    last_index = index
                    limited? ? raise(Exception) : @slice_number += 1
                  end
                end
              end
              if units_count > 0
                @map.commit(node, @slice_number, [last_index, -1])
              end
            rescue Exception
              break
            end
          else
            @map.commit(node, @slice_number, true)
          end
        end
      end

      def process_by_node!(root)
        units_count = 0
        parse(root) do |node|
          @map.commit(node, @slice_number, true)
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

      def sliceable?(node)
        able_to?(node, @options)
      end

    end
  
  end
end