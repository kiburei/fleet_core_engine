class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :authenticate_user!

  def authorize_admin!
    redirect_to root_path, alert: "Unauthorized" unless current_user.admin?
  end
end
