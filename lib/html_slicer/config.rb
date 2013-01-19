require 'active_support/configurable'

module HtmlSlicer
  # Configures global settings for HtmlSlicer
  #
  # === Default global configuration options
  #
  #   window = 4
  #   outer_window = 0
  #   left = 0
  #   right = 0
  #   param_name = :slice
  #
  # === Override/complete global configuration
  #
  #   HtmlSlicer.configure do |config|
  #     config.slice = {:complete => /\s+|\z/, :maximum => 2000}
  #     config.resize = {:width => 300, :only => {:tag => 'iframe'}}
  #     config.window = 5
  #     config.param_name = :any_other_param_name
  #   end
  #
  # === Passing an argument (:symbol) creates stylized configuration, which can be used like that:
  #   
  #   HtmlSlicer.configure(:paged) do |config|
  #     config.as = :page
  #     config.param_name = :page
  #   end
  #
  #   class Post < ActiveRecord::Base
  #     slice :content, :config => :paged
  #   end
  #
  # * Missing options are inherited from global one.
  # 
  def self.configure(style = nil, &block)
    yield eval("@config#{"_#{style}" if style} ||= #{style ? "@config.duplicate" : "Configuration.new"}")
  end
  
  # Config accessor for HtmlSlicer. Accepts argument as a +style+.
  def self.config(style = nil)
    eval("@config#{"_#{style}" if style}") || raise("Config style '#{style}' is invalid.")
  end
  
  # need a Class for 3.0
  class Configuration #:nodoc:
    
    include ActiveSupport::Configurable
    
    config_accessor :as
    config_accessor :slice
    config_accessor :resize
    config_accessor :processors
    config_accessor :window
    config_accessor :outer_window
    config_accessor :left
    config_accessor :right
    config_accessor :param_name
    config_accessor :cache_to

    def slice # Ugly coding. Override Hash::slice method
      config[:slice]
    end

    def param_name
      config.param_name.respond_to?(:call) ? config.param_name.call : config.param_name
    end
    
    def duplicate
      Configuration.new.tap do |c|
        c.config.replace(config.deep_copy)
      end
    end
    
  end
  
  configure do |config| # Setup default global configuration
    config.window = 4
    config.outer_window = 0
    config.left = 0
    config.right = 0
    config.param_name = :slice
  end
  
end