module HtmlSlicer
  module Installer
    
    # The basic implementation method.
    #
    #   slice <method_name>, <configuration>, [:config => <:style>]*
    #
    # where: 
    # * <method_name> - any method or local variable which returns source String (can be called with .send()).
    # * <configuration> - Hash of configuration options and/or +:config+ parameter.
    #
    # === Example:
    # 
    #   class Article < ActiveRecord::Base
    #     slice :content, :as => :paged, :slice => {:maximum => 2000}, :resize => {:width => 600}
    #   end
    #
    # === Where:
    # * <tt>:content</tt> is a method name or local variable, that return a target String object.
    # * <tt>:as</tt> is a name of basic accessor for result.
    # * <tt>:slice</tt> is a hash of +slicing options+.
    # * <tt>:resize</tt> is a hash of +resizing options+.
    # 
    # You can define any configuration key you want.
    # Otherwise, default configuration options (if available) will be picked up automatically.
    # 
    # === All configuration keys:
    # * <tt>:as</tt> is a name of basic accessor for sliced +object+.
    # * <tt>:slice</tt> is a hash of slicing options*.
    # * <tt>:resize</tt> is a hash of resizing options*.
    # * <tt>:processors</tt> - processors names*.
    # * <tt>:window</tt> - parameter for ActionView: The "inner window" size (4 by default).
    # * <tt>:outer_window</tt> - parameter for ActionView: The "outer window" size (0 by default).
    # * <tt>:left</tt> - parameter for ActionView: The "left outer window" size (0 by default).
    # * <tt>:right</tt> - parameter for ActionView: The "right outer window" size (0 by default).
    # * <tt>:params</tt> - parameter for ActionView: url_for parameters for the links (:controller, :action, etc.)
    # * <tt>:param_name</tt> - parameter for ActionView: parameter name for slice number in the links. Accepts +symbol+, +string+, +array+.
    # * <tt>:remote</tt> - parameter for ActionView: Ajax? (false by default)
    #
    # === Block-style configuration example:
    # 
    #   slice *args do |config|
    #     config.as = :paged
    #     config.slice.merge! {:maximum => 1500}
    #     config.resize = nil
    #   end
    #
    #   # *args = method name or local variable, and/or +:config+ parameter.
    #
    #
    # === Premature configuration (+:config+ parameter):
    # Stylizied general configuration can be used for many implementations, such as:
    #   
    #  # For example, we set the global stylized config:
    #
    #   HtmlSlicer.configure(:paged_config) do |config|
    #     config.as = :page
    #     config.slice = {:maximum => 300}
    #     config.window = 4
    #     config.outer_window = 0
    #     config.left = 0
    #     config.right = 0
    #     config.param_name = :slice
    #   end
    #   
    #  # Now we can use it as next:
    #
    #   slice *args, :config => :paged_config
    #     
    #   You can also pass another configuration options directrly as arguments
    #   and/or the block to clarify the config along with used global:
    #
    #   slice *args, :as => :chapter, :config => :paged_config do |config|
    #     config.slice.merge! {:unit => {:tag => 'h1', :class => 'chapter'}, :maximum => 1}
    #   end
    #
    # === Skipping slicing:
    # 
    #   To skip slicing (for example, if you want to use only resizing feature)
    #   you can nilify +slice+ option at all:
    #   
    #   slice :content, :slice => nil, :resize => {:width => 300}
    #
    #   Notice: without +:slice+ neither +:resize+ options, using HtmlSlicer becomes meaningless. :)
    #
    # === See README.rdoc for details about +:slice+ and +:resize+ options etc.
    #
    def slice(*args, &block)
      attr_name = args.first
      raise(NameError, "Attribute name expected!") unless attr_name
      
      options = args.extract_options!
      config = HtmlSlicer.config(options.delete(:config)).duplicate # Configuration instance for each single one implementation
      if options.present? # Accepts options from args
        options.each do |key, value|
          config.send("#{key}=", value)
        end
      end
      if block_given? # Accepts options from block
        yield config
      end
      if config.processors
        Array.wrap(config.processors).each do |name|
          HtmlSlicer.load_processor!(name)
        end
      end
      method_name = config.as||"#{attr_name}_slice"
      config.cache_to = "#{method_name}_cache" if config.cache_to == true
      class_eval do
        define_method method_name do
          var_name = "@_#{method_name}"
          instance_variable_get(var_name)||instance_variable_set(var_name, HtmlSlicer::Interface.new(self, attr_name, config.config))
        end
      end
      if config.cache_to && self.superclass == ActiveRecord::Base
        before_save do
          send(method_name).load!
        end
      end
    end
    
  end
end