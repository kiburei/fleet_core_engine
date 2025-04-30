class MaintenancesController < ApplicationController
  before_action :set_maintenance, only: %i[edit update destroy show]

  def index
    @maintenance = Maintenance.new

    if params[:fleet_provider_id]
      @fleet_provider = FleetProvider.find(params[:fleet_provider_id])
      @maintenances = @fleet_provider.maintenances.includes(:vehicle)
    else
      @maintenances = if current_user.admin?
                        Maintenance.all.includes(:vehicle)
      else
                        Maintenance.where(fleet_provider_id: current_user.fleet_provider_id).includes(:vehicle)
      end
    end
  end

  def new
    if !current_user.fleet_provider_admin? || !current_user.fleet_provider_manager? || !current_user.fleet_provider_user?
      redirect_to maintenances_path, alert: "You are not authorized to create maintenance records."
      return
    end
    @maintenance = Maintenance.new
  end

  def show
    if current_user.fleet_provider_id != @maintenance.fleet_provider_id && !current_user.admin?
      redirect_to maintenances_path, alert: "You are not authorized to view this maintenance record."
      nil
    end
  end

  def create
    # only fleet provider admin can and fleet provider manager can create maintenance records
    if !current_user.fleet_provider_admin? || !current_user.fleet_provider_manager? || !current_user.fleet_provider_user?
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
    if current_user.fleet_provider_id != @maintenance.fleet_provider_id && !current_user.fleet_provider_admin? || !current_user.fleet_provider_manager?
      redirect_to maintenances_path, alert: "You are not authorized to edit this maintenance record."
      nil
    end
  end

  def update
    if current_user.fleet_provider_id != @maintenance.fleet_provider_id && !current_user.fleet_provider_admin? || !current_user.fleet_provider_manager?
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
