class Admin::UsersController < ApplicationController
  before_action :authorize_admin!, only: [ :update ]
  before_action :set_user, only: [ :show, :edit, :update ]
  def index
    if current_user.admin?
      @users = User.all
    else
      @users = User.where(fleet_provider_id: current_user.fleet_provider_id)
    end
  end

  def show
  end

  def edit
  end

  def update
    # assign multiple fleets to user
    if params[:user][:fleet_provider_ids].present?
      params[:user][:fleet_provider_ids].each do |fleet_provider_id|
        fleet_provider_user = FleetProviderUser.find_or_initialize_by(user_id: @user.id, fleet_provider_id: fleet_provider_id)
        fleet_provider_user.save
      end
    end
    # remove fleets from user
    if params[:user][:remove_fleet_provider_ids].present?
      params[:user][:remove_fleet_provider_ids].each do |fleet_provider_id|
        fleet_provider_user = FleetProviderUser.find_by(user_id: @user.id, fleet_provider_id: fleet_provider_id)
        fleet_provider_user.destroy if fleet_provider_user
      end
    end


    if @user.update(user_params)
      redirect_to admin_users_path, notice: "User was successfully updated."
    else
      render :edit
    end
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :other_name, :email, :phone_number, :password, :password_confirmation, role_ids: [], fleet_provider_ids: [])
  end

  def set_user
    @user = User.find(params[:id])
  end
end
