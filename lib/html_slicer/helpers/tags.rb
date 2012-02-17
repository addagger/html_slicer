# This part of code is almost completely ported from +Kaminari+ gem by Akira Matsuda.
# Look at http://github.com/amatsuda/kaminari/tree/master/lib/kaminari/helpers
module HtmlSlicer
  module Helpers
    
    # A tag stands for an HTML tag inside the paginator.
    # Basically, a tag has its own partial template file, so every tag can be
    # rendered into String using its partial template.
    #
    # The template file should be placed in your app/views/html_slicer/ directory
    # with underscored class name (besides the "Tag" class. Tag is an abstract
    # class, so _tag parital is not needed).
    #   e.g.)  PrevLink  ->  app/views/html_slicer/_prev_link.html.erb
    #
    # When no matching template were found in your app, the engine's pre
    # installed template will be used.
    #   e.g.)  Paginator  ->  $GEM_HOME/html_slicer-x.x.x/app/views/html_slicer/_paginator.html.erb
        
    class Tag    
      def initialize(template, options = {}) #:nodoc:
        @template, @options = template, options.dup
        @param_name = @options.delete(:param_name)
        @theme = @options[:theme] ? "#{@options.delete(:theme)}/" : ''
        @params = @options[:params] ? template.params.merge(@options.delete :params) : template.params        
      end
      
      def to_s(locals = {}) #:nodoc:
        @template.render :partial => "html_slicer/#{@theme}#{self.class.name.demodulize.underscore}", :locals => @options.merge(locals)
      end

      def slice_url_for(slice)
        # +HtmlSlicer::SmartParams+: return deep merged params with a new slice number value.
        @template.url_for HtmlSlicer::SmartParams.new(@params, @param_name, (slice <= 1 ? nil : slice))
      end
    end

    # Tag that contains a link
    module Link
      # target slice number
      def slice
        raise 'Override slice with the actual slice value to be a slice.'
      end
      # the link's href
      def url
        slice_url_for slice
      end
      def to_s(locals = {}) #:nodoc:
        super locals.merge(:url => url)
      end
    end

    # A slice
    class Slice < Tag
      include Link
      # target slice number
      def slice
        @options[:slice]
      end
      def to_s(locals = {}) #:nodoc:
        super locals.merge(:slice => slice)
      end
    end

    # Link with slice number that appears at the leftmost
    class FirstSlice < Tag
      include Link
      def slice #:nodoc:
        1
      end
    end

    # Link with slice number that appears at the rightmost
    class LastSlice < Tag
      include Link
      def slice #:nodoc:
        @options[:slice_number]
      end
    end

    # The "previous" slice of the current slice
    class PrevSlice < Tag
      include Link
      def slice #:nodoc:
        @options[:current_slice] - 1
      end
    end

    # The "next" slice of the current slice
    class NextSlice < Tag
      include Link
      def slice #:nodoc:
        @options[:current_slice] + 1
      end
    end

    # Non-link tag that stands for skipped slices...
    class Gap < Tag
    end
  end
end