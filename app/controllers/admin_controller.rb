class AdminController < ApplicationController
  before_action :authenticate_user!
  layout 'admin'
  
  private
  
  def ensure_admin_user
    redirect_to root_path unless current_user&.admin?
  end
end