class MaintenancesController < ApplicationController
  before_action :set_maintenance, only: %i[edit update destroy show]

  def index
    @maintenance = Maintenance.new

    if params[:vehicle_id]
      @maintenances = Maintenance.where(vehicle_id: params[:vehicle_id]).includes(:vehicle)
    else
      @maintenances = if current_user.admin?
                        Maintenance.all.includes(:vehicle)
      else
                        Maintenance.where(fleet_provider_id: current_user.fleet_providers).includes(:vehicle)
      end
    end
  end

  def new
    unless current_user.fleet_provider_admin? || current_user.fleet_provider_manager? || current_user.fleet_provider_user?
      redirect_to maintenances_path, alert: "You are not authorized to create maintenance records."
      return
    end
    @maintenance = Maintenance.new
  end

  def show
    unless current_user.fleet_providers.include?(@maintenance.fleet_provider) || current_user.admin? || current_user.fleet_provider_user? || current_user.fleet_provider_manager?
      redirect_to maintenances_path, alert: "You are not authorized to view this maintenance record."
      nil
    end
  end

  def create
    # only fleet provider admin can and fleet provider manager can create maintenance records
    unless current_user.fleet_provider_admin? || current_user.fleet_provider_manager? || current_user.fleet_provider_user?
      redirect_to maintenances_path, alert: "You are not authorized to create maintenance records."
      return
    end

    @maintenance = Maintenance.new(maintenance_params)
    if @maintenance.save
      redirect_to maintenance_path(@maintenance), notice: "Maintenance record added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    unless current_user.fleet_providers.include?(@maintenance.fleet_provider) || current_user.fleet_provider_admin? || current_user.fleet_provider_manager?
      redirect_to maintenances_path, alert: "You are not authorized to edit this maintenance record."
      nil
    end
  end

  def update
    unless current_user.fleet_providers.include?(@maintenance.fleet_provider) || current_user.fleet_provider_admin? || current_user.fleet_provider_manager?
      redirect_to maintenances_path, alert: "You are not authorized to update this maintenance record."
      nil
    end

    if @maintenance.update(maintenance_params)
      redirect_to vehicle_path(@vehicle), notice: "Maintenance record updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if current_user.fleet_provider_id != @maintenance.fleet_provider_id && !current_user.fleet_provider_admin? || !current_user.fleet_provider_manager?
      redirect_to maintenances_path, alert: "You are not authorized to delete this maintenance record."
      return
    end

    @maintenance.destroy
    redirect_to vehicle_path(@vehicle), notice: "Maintenance record removed."
  end

  private

  def set_maintenance
    @maintenance = Maintenance.find(params[:id])
  end

  def maintenance_params
    params.require(:maintenance).permit(:fleet_provider_id, :vehicle_id, :maintenance_type, :description, :maintenance_date, :maintenance_cost, :service_provider, :odometer, :next_service_due)
  end
end
