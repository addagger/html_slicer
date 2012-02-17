require 'html_slicer/installer'

module HtmlSlicer
  
  module ActiveRecordExtension
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      class_eval do
        include HtmlSlicer::Installer
      end
    end

    module InstanceMethods

    end
            
  end
  
end
