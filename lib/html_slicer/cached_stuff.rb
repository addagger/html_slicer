require 'digest/sha1'

module HtmlSlicer
  # Object to be serialized and dumped as cache storage.
  # Include +resizing+ and +slicing+ objects, and original text's hexdigest hash value to provide authenticity.
  # During the runtime object is used as an +maps+ accessor too.
  
  class CachedStuff
    attr_reader :version, :hexdigest, :resizing, :slicing
    attr_accessor :changed, :time
    
    def initialize(text = nil)
      @version = HtmlSlicer::VERSION
      @changed = false
      self.hexdigest_for = text if text
    end
    
    def hexdigest_for=(text)
      hex = Digest::SHA1.hexdigest(text)
      unless hex == @hexdigest
        @changed = true
        @hexdigest = hex
      end
      hex
    end
    
    def slicing=(object)
      case object
      when HtmlSlicer::Mappers::Slicing, nil then
        @changed = true unless object.try(:options).try(:hexdigest) == @slicing.try(:options).try(:hexdigest)
        @slicing = object
      else
        raise(TypeError, "HtmlSlicer::Mappers::Slicing or nil expected, '#{object.class}' passed")
      end
    end
    
    def resizing=(object)
      case object
      when HtmlSlicer::Mappers::Resizing, nil then
        @changed = true unless object.try(:options).try(:hexdigest) == @slicing.try(:options).try(:hexdigest)
        @resizing = object
      else
        raise(TypeError, "HtmlSlicer::Mappers::Resizing or nil expected, '#{object.class}' passed")
      end
    end
    
    def valid_text?(text)
      Digest::SHA1.hexdigest(text) == @hexdigest
    end
    
    def valid_resizing_options?(options)
      options.try(:hexdigest) == @resizing.try(:options).try(:hexdigest)
    end

    def valid_slicing_options?(options)
      options.try(:hexdigest) == @slicing.try(:options).try(:hexdigest)
    end

    def changed?
      @changed
    end
    
    # Serialize self, using Marshal and Base64 encoding
    def to_dump
      @time = Time.now
      Base64.encode64(Marshal.dump(self))
    end
    
  end
  
end