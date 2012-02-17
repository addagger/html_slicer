# This part of code is almost completely ported from +Kaminari+ gem by Akira Matsuda.
# Look at http://github.com/amatsuda/kaminari/tree/master/lib/kaminari/helpers

require 'active_support/inflector'
require 'action_view'
require 'action_view/log_subscriber'
require 'action_view/context'
require 'html_slicer/helpers/smart_params'
require 'html_slicer/helpers/tags'

module HtmlSlicer
  
  module Helpers
    # The main container tag
    
    # Configure ActiveSupport inflections to pluralize 'slice' in a correct way = 'slices'. # By default would be 'slouse'.
    ActiveSupport::Inflector.inflections do |inflect|
      inflect.plural 'slice', 'slices'
      inflect.singular 'slice', 'slice'
    end
    
    class Slicer < Tag
      # so that this instance can actually "render"
      include ::ActionView::Context

      def initialize(template, options) #:nodoc:
        @window_options = {}.tap do |h|
          h[:window] = options.delete(:window) || options.delete(:inner_window)
          outer_window = options.delete(:outer_window)
          h[:left] = options.delete(:left)
          h[:left] = outer_window if h[:left] == 0
          h[:right] = options.delete(:right)
          h[:right] = outer_window if h[:right] == 0
        end
        @template, @options = template, options
        @theme = @options[:theme] ? "#{@options[:theme]}/" : ''
        @options[:current_slice] = SliceProxy.new @window_options.merge(@options), @options[:current_slice], nil
        # initialize the output_buffer for Context
        @output_buffer = ActionView::OutputBuffer.new
      end

      # render given block as a view template
      def render(&block)
        instance_eval &block if @options[:slice_number] > 1
        @output_buffer
      end

      # enumerate each slice providing sliceProxy object as the block parameter
      # Because of performance reason, this doesn't actually enumerate all slices but slices that are seemingly relevant to the paginator.
      # "Relevant" slices are:
      # * slices inside the left outer window plus one for showing the gap tag
      # * slices inside the inner window plus one on the left plus one on the right for showing the gap tags
      # * slices inside the right outer window plus one for showing the gap tag
      def each_relevant_slice
        return to_enum(:each_relevant_slice) unless block_given?

        relevant_slices(@window_options.merge(@options)).each do |i|
          yield SliceProxy.new(@window_options.merge(@options), i, @last)
        end
      end
      alias each_slice each_relevant_slice

      def relevant_slices(options)
        left_window_plus_one = 1.upto(options[:left] + 1).to_a
        right_window_plus_one = (options[:slice_number] - options[:right]).upto(options[:slice_number]).to_a
        inside_window_plus_each_sides = (options[:current_slice] - options[:window] - 1).upto(options[:current_slice] + options[:window] + 1).to_a

        (left_window_plus_one + inside_window_plus_each_sides + right_window_plus_one).uniq.sort.reject {|x| (x < 1) || (x > options[:slice_number])}
      end
      private :relevant_slices

      def slice_tag(slice)
        @last = Slice.new @template, @options.merge(:slice => slice)
      end

      %w[first_slice prev_slice next_slice last_slice gap].each do |tag|
        eval <<-DEF
          def #{tag}_tag
            @last = #{tag.classify}.new @template, @options
          end
        DEF
      end

      def to_s #:nodoc:
        subscriber = ActionView::LogSubscriber.log_subscribers.detect {|ls| ls.is_a? ActionView::LogSubscriber}
        return super @window_options.merge(@options).merge :slicer => self unless subscriber

        # dirty hack to suppress logging render_partial
        class << subscriber
          alias_method :render_partial_with_logging, :render_partial
          # do nothing
          def render_partial(event); end
        end

        ret = super @window_options.merge(@options).merge :slicer => self

        class << subscriber
          alias_method :render_partial, :render_partial_with_logging
          undef :render_partial_with_logging
        end
        ret
      end

      # Wraps a "slice number" and provides some utility methods
      class SliceProxy
        include Comparable

        def initialize(options, slice, last) #:nodoc:
          @options, @slice, @last = options, slice, last
        end

        # the slice number
        def number
          @slice
        end

        # current slice or not
        def current?
          @slice == @options[:current_slice]
        end

        # the first slice or not
        def first?
          @slice == 1
        end

        # the last slice or not
        def last?
          @slice == @options[:slice_number]
        end

        # the previous slice or not
        def prev?
          @slice == @options[:current_slice] - 1
        end

        # the next slice or not
        def next?
          @slice == @options[:current_slice] + 1
        end

        # within the left outer window or not
        def left_outer?
          @slice <= @options[:left]
        end

        # within the right outer window or not
        def right_outer?
          @options[:slice_number] - @slice < @options[:right]
        end

        # inside the inner window or not
        def inside_window?
          (@options[:current_slice] - @slice).abs <= @options[:window]
        end

        # The last rendered tag was "truncated" or not
        def was_truncated?
          @last.is_a? Gap
        end

        def to_i
          number
        end

        def to_s
          number.to_s
        end

        def +(other)
          to_i + other.to_i
        end

        def -(other)
          to_i - other.to_i
        end

        def <=>(other)
          to_i <=> other.to_i
        end
      end
    end
  end
end