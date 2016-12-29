require 'digest/sha1'

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

    def hexdigest
      Digest::SHA1.hexdigest(string_value)
    end
    
    def string_value
      instance_variables.map {|name| name.to_s + ":" + instance_variable_get(name).to_s}.join
    end
    
  end
  
  class SlicingOptions < Options #:nodoc:
    attr_reader :unit, :maximum, :complete, :text_break, :limit
    
    def initialize(options)
      super(options)
      @unit = case options[:unit]
      when Hash, Regexp then options[:unit]
      when String then /#{options[:unit]}/
      when nil then /&#?\w+;|\S/
      else raise "Invalid :unit definition '#{options[:unit].inspect}'"
      end
      @maximum = case options[:maximum]
      when Integer then
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
      when Integer, nil then options[:limit]
      else raise "Invalid :limit option definition '#{options[:limit].inspect}'"
      end
      @text_break = options[:text_break]
    end

  end
  
  class ResizingOptions < Options
    attr_reader :width
    
    def initialize(options)
      super(options)
      @width = options[:width].to_i
    end

  end
  
end