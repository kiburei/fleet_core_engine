class ApplicationController < ActionController::Base
  config.web_console.whitelisted_ips = "102.0.8.36"
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :authenticate_user!

  def authorize_admin!
    redirect_to root_path, alert: "Unauthorized" unless current_user.admin?
  end
end
