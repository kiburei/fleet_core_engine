module ApplicationHelper
  def number_with_comma(number)
    number.to_s.reverse.gsub(/...(?=.)/, '\&,').reverse
  end

  def email_spacer(amount = 20)
    render "rui/shared/email_spacer", amount: amount
  end

  def email_action(action, url, options={})
    align = options[:align] ||= "left"
    theme = options[:theme] ||= "primary"
    fullwidth = options[:fullwidth] ||= false
    render "rui/shared/email_action", align: align, theme: theme, action: action, url: url, fullwidth: fullwidth
  end

  def email_callout(&block)
    render "rui/shared/email_callout", block: block
  end

  # Tab helper methods for status filtering
  def tab_class_for(tab_status, current_status)
    base_classes = "py-2 px-4 rounded-lg transition ease-in-out duration-300 font-medium flex items-center gap-2"
    
    if tab_status == current_status
      "#{base_classes} bg-slate-50 dark:bg-slate-900 text-primary-600 dark:text-primary-400 dark:hover:bg-slate-900/80"
    else
      "#{base_classes} hover:bg-slate-50 hover:text-primary-600 dark:hover:text-primary-400 group dark:text-slate-300 dark:hover:bg-slate-900"
    end
  end

  def count_badge_class_for(tab_status, current_status)
    base_classes = "rounded px-1 py-px text-xs font-semibold"
    
    if tab_status == current_status
      "#{base_classes} bg-primary-600 text-white"
    else
      "#{base_classes} bg-slate-200 text-slate-500"
    end
  end
end
