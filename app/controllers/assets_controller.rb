class AssetsController < ApplicationController
  def railsui_theme
    render file: Rails.root.join('app/assets/stylesheets/railsui/theme.css'), content_type: 'text/css'
  end

  def railsui_actiontext
    render file: Rails.root.join('app/assets/stylesheets/railsui/actiontext.css'), content_type: 'text/css'
  end

  def railsui_buttons
    render file: Rails.root.join('app/assets/stylesheets/railsui/buttons.css'), content_type: 'text/css'
  end

  def railsui_headings
    render file: Rails.root.join('app/assets/stylesheets/railsui/headings.css'), content_type: 'text/css'
  end

  def railsui_forms
    render file: Rails.root.join('app/assets/stylesheets/railsui/forms.css'), content_type: 'text/css'
  end

  def railsui_navigation
    render file: Rails.root.join('app/assets/stylesheets/railsui/navigation.css'), content_type: 'text/css'
  end

  def service_worker
    render file: Rails.root.join('public/service-worker.js'), content_type: 'application/javascript'
  end
end 