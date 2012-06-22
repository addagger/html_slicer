module HtmlSlicer
  module Makers
    
    class Slicing # Slicing engine
      attr_reader :options, :map

      def initialize(document, options = {})
        raise(TypeError, "HTML::Document expected, '#{document.class}' passed") unless document.is_a?(HTML::Document)
        @options = SliceOptions.new(options)
        @map = [Hash.new]
        @options.unit.is_a?(Hash) ? slice_document_by_node!(document.root) : slice_document_by_text!(document.root)
      end

      # Resturn number of slices.
      def slice_number
        @map.size
      end

      private

      include HtmlSlicer::Utilities::ParseNode
      include HtmlSlicer::Utilities::NodeMatchExtension

      def slice_document_by_text!(root)
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
                    @map.last[node.object_id] = Range.new(last_index, index-1)
                    last_index = index
                    limited? ? raise(Exception) : @map << Hash.new
                  else
                    index = match.end(0)
                  end
                  if units_count > 0
                    @map.last[node.object_id] = Range.new(last_index, -1)
                  end
                end
              rescue Exception
                break
              end
            else
              @map.last[node.object_id] = Range.new(0, -1)
            end
          else
            @map.last[node.object_id] = true
          end
        end
      end

      def slice_document_by_node!(root)
        units_count = 0
        parse(root) do |node|
          if node.is_a?(HTML::Text)
            @map.last[node.object_id] = Range.new(0, -1)
          else
            @map.last[node.object_id] = true
          end
          if node.match(@options.unit) && sliceable?(node)
            units_count += 1
            if units_count == @options.maximum
              units_count = 0
              limited? ? break : @map << Hash.new
            end
          end
        end
      end

      def limited?
        @options.limit && slice_number >= @options.limit
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