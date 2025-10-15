class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin_user
  layout 'admin'
  
  private
  
  def ensure_admin_user
    redirect_to root_path unless current_user&.admin?
  end
  
  def system_admin?
    current_user&.admin?
  end
  
  def fleet_admin?
    current_user&.fleet_provider_admin? || current_user&.fleet_provider_owner?
  end
  
  def current_fleet_provider
    @current_fleet_provider ||= begin
      if system_admin?
        nil # System admin can see all fleet providers
      else
        current_user.fleet_providers.first
      end
    end
  end
  
  def ensure_system_admin
    redirect_to root_path unless system_admin?
  end
  
  def ensure_fleet_access
    redirect_to root_path unless system_admin? || fleet_admin?
  end
end
