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
    attr_reader :options, :current_slice, :document
        
    delegate :sliced?, :resized?, :slice_number, :to => :document
    
    def initialize(env, method_name, options = {})
      @options = options
      @document = Document.new(env, method_name, options)
      @current_slice = 1
    end

    # General slicing method. Passing the argument changes the slice.
    def slice!(slice = nil)
      raise(Exception, "Slicing unavailable!") unless sliced?
      if slice.present?
        if slice.to_i.in?(1..slice_number)
          @current_slice = slice.to_i
        else
          raise(ArgumentError, "Slice number must be Fixnum in (1..#{slice_number}). #{slice.inspect} passed.")
        end
      end
      to_s
    end
    
    # Textual representation according to a current slice.
    def to_s
      document.to_s(current_slice)
    end
    
    def inspect
      to_s
    end
    
    def method_missing(*args, &block)
      to_s.send(*args, &block)
    end
    
    # Return the current slice is a last or not?
    def last_slice?
      current_slice == slice_number
    end

  end
  
end