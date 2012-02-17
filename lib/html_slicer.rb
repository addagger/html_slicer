# encoding: utf-8

require "html_slicer/version"

module HtmlSlicer
  
  def self.load!
    require 'html_slicer/utilities'
    require 'html_slicer/config'
    require 'html_slicer/options'
    require 'html_slicer/processor'
    require 'html_slicer/slicing'
    require 'html_slicer/engine'
    require 'html_slicer/helpers/action_view_extension'
    require 'html_slicer/helpers/slicer'
    require 'html_slicer/railtie'
  end
  
end
  
HtmlSlicer.load!