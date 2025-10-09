class MaintenancesController < ApplicationController
  before_action :set_maintenance, only: %i[edit update destroy show]

  def index
    @maintenance = Maintenance.new
    @per_page = params[:per_page] || 10
    @current_status = params[:status] || 'active'

    # Base query
    if params[:vehicle_id]
      base_maintenances = Maintenance.where(vehicle_id: params[:vehicle_id]).includes(:vehicle, :fleet_provider)
    else
      base_maintenances = if current_user.admin?
                            Maintenance.all.includes(:vehicle, :fleet_provider)
                          else
                            Maintenance.where(fleet_provider_id: current_user.fleet_providers).includes(:vehicle, :fleet_provider)
                          end
    end

    # Get all status counts for tabs
    @status_tabs = {
      'pending' => {
        label: 'Pending',
        count: base_maintenances.where(status: 'pending').count
      },
      'scheduled' => {
        label: 'Scheduled',
        count: base_maintenances.where(status: 'scheduled').count
      },
      'in_progress' => {
        label: 'In Progress',
        count: base_maintenances.where(status: 'in_progress').count
      },
      'completed' => {
        label: 'Completed',
        count: base_maintenances.where(status: 'completed').count
      },
      'cancelled' => {
        label: 'Cancelled',
        count: base_maintenances.where(status: 'cancelled').count
      }
    }
    
    @total_count = @status_tabs.values.sum { |tab| tab[:count] }
    @current_status = params[:status] || 'pending'

    # Filter by status
    @maintenances = if @current_status == 'all'
                      base_maintenances
                    else
                      base_maintenances.where(status: @current_status)
                    end

    # Apply search filter if present
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @maintenances = @maintenances.joins(:vehicle).where(
        "maintenances.maintenance_type ILIKE ? OR maintenances.description ILIKE ? OR maintenances.service_provider ILIKE ? OR vehicles.registration_number ILIKE ?",
        search_term, search_term, search_term, search_term
      )
    end
    
    @maintenances = @maintenances.page(params[:page]).per(@per_page)
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
