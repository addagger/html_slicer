module HtmlSlicer
  
  # Make options adjective and convinient for processing needs.
  
  class Options #:nodoc:
    # Superclass
    attr_reader :only, :except
    def initialize(options)
      options ||= {}
      @only = options[:only]
      @except = options[:except]
    end
  end
  
  class SliceOptions < Options #:nodoc:
    attr_reader :unit, :maximum, :complete, :limit
    def initialize(options)
      super(options)
      @unit = case options[:unit]
      when String, Regexp, Hash then options[:unit]
      when nil then :char
      else raise "Invalid :unit definition '#{options[:unit].inspect}'"
      end
      @maximum = case options[:maximum]
      when Fixnum then
        if options[:maximum] > 0
          options[:maximum]
        else
          raise "Invalid :maximum definition. Has to be more than zero, '#{options[:unit].inspect}' passed"
        end
      when nil then case unit
                    when String, Regexp then 300
                    when Hash then 10
                    else 2000
                    end
      else raise "Invalid :maximum definition '#{options[:maximum].inspect}'"
      end
      @complete = case options[:complete]
      when Regexp then options[:complete]
      when nil then nil
      else raise "Invalid :complete option definition '#{options[:complete].inspect}'"
      end
      @limit = case options[:limit]
      when Fixnum, nil then options[:limit]
      else raise "Invalid :limit option definition '#{options[:limit].inspect}'"
      end
    end
  end
  
  class ResizeOptions < Options
    attr_reader :width
    def initialize(options)
      super(options)
      @width = options[:width]
    end
  end
  
end