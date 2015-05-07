require 'html_slicer/options'
require 'html_slicer/processor'
require 'html_slicer/cached_stuff'
require 'html_slicer/mappers/slicing'
require 'html_slicer/mappers/resizing'

module HtmlSlicer
  
  # Interface code.
  # Accepts slice number, store it into instance variable and provides resulted String.
  # 
  # === Example:
  # 
  # @article = Article.find(1)
  # @article_paged = @article.paged.slice!(params[:slice])
  #
  
  class Interface # General accessor instance
    include HtmlSlicer::Mappers
   
    attr_reader :options, :document, :current_slice, :cached_stuff

    delegate :slicing, :resizing, :to => :cached_stuff

    def initialize(env, method_name, options = {})
      @env, @method_name = env, method_name
      @options = options
      @resizing_options = ResizingOptions.new(options[:resize]) if options[:resize]
      @slicing_options = SlicingOptions.new(options[:slice]) if options[:slice]
      @current_slice = 1
      load!
    end
    
    def inspect
      "'#{to_s}'"
    end
    
    # Getting source content
    def source
      case options[:processors].present?
      when true then HtmlSlicer::Process.iterate(@env.send(@method_name), options[:processors])
      else
        @env.send(@method_name)
      end
    end

    # Process initializer
    def load!
      text = source||""
      @cached_stuff ||= 
      begin
        if options[:cache_to] # Getting recorded hash dump
          Marshal.load(Base64.decode64(@env.send(options[:cache_to]))).tap do |cached_stuff|
            if cached_stuff.time < Date.new(2012,7,25)
              #### CACHE OUT OF DATE ####
              warn "WARNING: html_slicer's cached stuff for #{@env.class.name} records has become unacceptable because of code changes. Update each record again. Visit http://vkvon.ru/projects/html_slicer for further details."
              raise Exception 
            end
          end
        else
          raise Exception
        end
      rescue Exception, TypeError, NoMethodError # New cache object otherwise
        CachedStuff.new
      end
      if @document.blank? || !@cached_stuff.valid_text?(text) # Initialize new @document if not exist or content has been changed
        @document = ::HTML::Document.new(text)
        @cached_stuff.hexdigest_for = text
      end
      if @cached_stuff.changed? || !@cached_stuff.valid_resizing_options?(@resizing_options) # Initialize new resizing process if the content or options has been changed
        if @resizing_options
          @cached_stuff.resizing = Resizing.new(@document, @resizing_options)
        else
          @cached_stuff.resizing = nil
        end
      end
      if @cached_stuff.changed? || !@cached_stuff.valid_slicing_options?(@slicing_options) # Initialize new slicing process if the content or options has been changed
        if @slicing_options
          @cached_stuff.slicing = Slicing.new(@document, @slicing_options)
        else
          @cached_stuff.slicing = nil
        end
      end
      if @cached_stuff.changed? # Serialize and dump the cache if any changes provided
        @cached_stuff.changed = false
        if options[:cache_to]
          @env.send("#{options[:cache_to]}=", @cached_stuff.to_dump)
        end
      end
    end

    # Return number of slices.
    def slice_number
      sliced? ? slicing.slice_number : 1
    end

    # General slicing method. Passing the argument changes the +current_slice+.
    def slice!(slice = nil)
      raise(Exception, "Slicing unavailable!") unless sliced?
      if slice.present?
        if slice.to_i.in?(1..slice_number)
          @current_slice = slice.to_i
        else
          raise(ArgumentError, "Slice number must be Fixnum in (1..#{slice_number}). #{slice.inspect} passed.")
        end
      end
      self
    end

    def to_s(&block)
      load!
      view(document.root, @current_slice, &block)
    end
    
    def method_missing(*args, &block)
      to_s.send(*args, &block)
    end

    # True if any HTML tag has been resized
    def resized?
      resizing ? resizing.map.any? : false
    end
    
    # True if any part of document has been sliced
    def sliced?
      slicing ? slicing.map.any? : false
    end

    # Return the current slice is a last or not?
    def last_slice?
      current_slice == slice_number
    end

    private

    # Return a textual representation of the node including all children.
    def view(node, slice, &block)
      slice = slice.to_i
      case node
      when ::HTML::Tag then
        children_view = node.children.map {|child| view(child, slice, &block)}.compact.join
        if resized?
          resizing.resize_node(node)
        end
        if sliced?
          if slicing.map.get(node, slice) || children_view.present?
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
        else
          node.to_s
        end
      when ::HTML::Text then
        if sliced?
          if range = slicing.map.get(node, slice)
            (range.is_a?(Array) ? node.content[Range.new(*range)] : node.content).tap do |export|
              unless range == true || (range.is_a?(Array) && range.last == -1) # broken text
                export << slicing.options.text_break if slicing.options.text_break
                if block_given?
                  yield self, export
                end
              end
            end
          end
        else
          node.to_s
        end
      when ::HTML::CDATA then
        node.to_s
      when ::HTML::Node then
        node.children.map {|child| view(child, slice, &block)}.compact.join
      end
    end

  end
  
end