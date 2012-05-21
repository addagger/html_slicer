module HtmlSlicer

  class SmartParams < Hash
    # Implements smart and flexible +params+ merging.
    # Method accepts passed +params+ hash and merge it with a new :+param_name+ and it's value.
    # In the case when you passed +param_name+ option as an Array, method returns merged new
    # instance of hashed params where all subhashes merged into the same way.
    #
    # === Example:
    #
    #   params = {:controller => "comments", :action => "show", :id => 34, :article_id => 3, :page => {:article => 2}}
    #
    #   :slice_params => [:page, :comment]
    #
    #   HtmlSlicer::SmartParams.new(params, slice_params, 34)
    #   # => {:controller => "comments", :action => "show", :id => 34, :article_id => 3, :page => {:article => 2, :comment => 34}}
    #    
    def initialize(params = {}, param_name = nil, value = nil)
      super()
      param_subhash = case param_name
      when Array then hashup(param_name.collect {|e| e.to_s} << value)
      when String, Symbol then {param_name.to_s => value}
      else {}
      end
      update(nested_merge(params, param_subhash))
    end
 
    private
    
    include HtmlSlicer::Utilities::HashupArray
    include HtmlSlicer::Utilities::NestedMergeHash
    
  end
  
end