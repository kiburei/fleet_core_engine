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
    if @user.update(user_params)
      redirect_to admin_user_path(@user), notice: "User was successfully updated."
    else
      render :edit
    end
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :other_name, :email, :phone_number, :fleet_provider_id, :password, :password_confirmation, role_ids: [])
  end

  def set_user
    @user = User.find(params[:id])
  end
end
