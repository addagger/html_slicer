# This part of code is almost completely ported from +Kaminari+ gem by Akira Matsuda.
# Look at http://github.com/amatsuda/kaminari/tree/master/lib/kaminari/helpers
module HtmlSlicer

  # The part of code, processing the +:param_name+ was rewritten by me.
  # Now you can define +:param_name+ as a +symbol+ or +string+, or as an +array of any object that responses +.to_s+ method and returns +string+.
  # Passing +array+ is the way to define nested :param_name.
  #
  # === Examples:
  # 
  #   :param_name => :page
  #   # means you define params[:page] as a slice key.
  #
  #   :param_name => [:article, :page]
  #   # means you define params[:article][:page] as a slice key.
  #
  
  module ActionViewExtension
    # A helper that renders the pagination links.
    #
    #   <%= slicer @article.paged %>
    #
    # ==== Options
    # * <tt>:window</tt> - The "inner window" size (4 by default).
    # * <tt>:outer_window</tt> - The "outer window" size (0 by default).
    # * <tt>:left</tt> - The "left outer window" size (0 by default).
    # * <tt>:right</tt> - The "right outer window" size (0 by default).
    # * <tt>:params</tt> - url_for parameters for the links (:controller, :action, etc.)
    # * <tt>:param_name</tt> - parameter name for slice number in the links. Accepts +symbol+, +string+, +array+.
    # * <tt>:remote</tt> - Ajax? (false by default)
    # * <tt>:ANY_OTHER_VALUES</tt> - Any other hash key & values would be directly passed into each tag as :locals value.
    def slice(object, options = {}, &block)
      slicer = HtmlSlicer::Helpers::Slicer.new self, object.options.reverse_merge(options).reverse_merge(:current_slice => object.current_slice, :slice_number => object.slice_number, :remote => false)
      slicer.to_s
    end

    # A simple "Twitter like" pagination link that creates a link to the next slice.
    #
    # ==== Examples
    # Basic usage:
    #
    #   <%= link_to_next_slice @article.paged, 'Next page' %>
    #
    # Ajax:
    #
    #   <%= link_to_next_slice @article.paged, 'Next page', :remote => true %>
    #
    # By default, it renders nothing if there are no more results on the next slice.
    # You can customize this output by passing a block.
    #
    #   <%= link_to_next_slice @article.paged, 'Next page' do %>
    #     <span>No More slices</span>
    #   <% end %>
    def link_to_next_slice(object, name, options = {}, &block)
      params = options[:params] ? self.params.merge(options.delete :params) : self.params
      param_name = options.delete(:param_name) || object.options.param_name
      link_to_unless object.last_slice?, name, HtmlSlicer::SmartParams.new(params, param_name, (object.current_slice + 1)), options.reverse_merge(:rel => 'next') do
        block.call if block
      end
    end

    # Renders a helpful message with numbers of displayed vs. total entries.
    # Ported from mislav/will_paginate
    #
    # ==== Examples
    # Basic usage:
    #
    #   <%= slice_entries_info @article.paged %>
    #   #-> Displaying paged 6 of 26
    #
    # By default, the message will use the stringified +method_name (+:as+ option)+ implemented as slicer method.
    # Override this with the <tt>:entry_name</tt> parameter:
    #
    #   <%= slice_entries_info @article.paged, :entry_name => 'page' %>
    #   #-> Displaying page 6 of 26
    def slice_entries_info(object, options = {})
      entry_name = options[:entry_name] || object.options.as
      output = ""
      if object.slice_number < 2
        output = case object.slice_number
        when 0 then "No #{entry_name} found"
        when 1 then "Displaying <b>1</b> #{entry_name}"
        else; "Displaying <b>all #{object.slice_number}</b> #{entry_name.to_s.pluralize}"
        end
      else
        output = %{Displaying #{entry_name} <b>#{object.current_slice}</b> of <b>#{object.slice_number}</b>}
      end
      output.html_safe
    end
  end
	
end
