require 'rails'

module HtmlSlicer
	class Railtie < ::Rails::Railtie
		config.before_initialize do
			ActiveSupport.on_load :active_record do
			  require 'html_slicer/models/active_record_extension'
				ActiveRecord::Base.send(:include, HtmlSlicer::ActiveRecordExtension)
			end
			ActiveSupport.on_load :action_view do
				ActionView::Base.send(:include, HtmlSlicer::ActionViewExtension)
			end
		end
	end
end