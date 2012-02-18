module HtmlSlicer
  class Processor
  
    attr_accessor :content
  
    def initialize(stuff = nil)
      @content = case stuff
      when String then stuff
      else
        if stuff.respond_to?(:to_s)
          stuff.to_s
        else
          raise(TypeError, "String or responsible :to_s object expected, #{stuff.class} passed.")
        end
      end
    end
  
    def make
    end
  
    def export
      make
    end
  
  end
  
  def self.load_processor!(name)
    if defined?(Rails.root) && Rails.root
      require File.expand_path(Rails.root.join("lib", "html_slicer_processors", "#{name.to_s.underscore}.rb"))
    end
  end
  
  module Process
    def self.iterate(content, processors = nil)
      if processors.present?
        Array.wrap(processors).each do |processor_name|
          processor = processor_name.to_s.classify.constantize
          raise(TypeError, "HtmlSlicer::Processor expected, #{processor.name} passed.") unless processor.superclass == HtmlSlicer::Processor
          content = processor.new(content).export
        end
      end
      content
    end
  end
  
end