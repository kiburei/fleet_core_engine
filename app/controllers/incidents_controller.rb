class IncidentsController < ApplicationController
  before_action :set_incident, only: %i[show edit update destroy]

  def index
    @incident = Incident.new
    @per_page = params[:per_page] || 10

    if params[:fleet_provider_id]
      @fleet_provider = FleetProvider.find(params[:fleet_provider_id])
      @incidents = @fleet_provider.incidents.includes(:vehicle, :driver).order(incident_date: :desc)
    else
      @incidents = if current_user.admin?
                    Incident.all.includes(:vehicle, :driver).order(incident_date: :desc)
      else
                    Incident.where(fleet_provider_id: current_user.fleet_provider_ids).includes(:vehicle, :driver).order(incident_date: :desc)
      end
    end
    
    @incidents = @incidents.page(params[:page]).per(@per_page)
  end

  def show
    unless current_user.fleet_providers.include?(@incident.fleet_provider) || current_user.admin?
      redirect_to incidents_path, alert: "You are not authorized to view this incident."
      nil
    end
  end

  def new
    unless current_user.fleet_provider_admin? || current_user.fleet_provider_manager? || current_user.fleet_provider_user? || current_user.fleet_provider_driver?
      redirect_to incidents_path, alert: "You are not authorized to create incidents."
      return
    end
    @incident = Incident.new
  end

  def edit
    unless current_user.fleet_providers.include?(@incident.fleet_provider) || current_user.fleet_provider_admin? || current_user.fleet_provider_manager?
      redirect_to incidents_path, alert: "You are not authorized to edit this incident."
      nil
    end
  end

  def create
    # only fleet provider admin can and fleet provider manager can create incidents
    unless current_user.fleet_provider_admin? || current_user.fleet_provider_manager? || current_user.fleet_provider_user? || current_user.fleet_provider_driver?
      redirect_to incidents_path, alert: "You are not authorized to create incidents."
      return
    end

    @incident = Incident.new(incident_params)
    if @incident.save
      redirect_to @incident, notice: "Incident was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    unless current_user.fleet_providers.include?(@incident.fleet_provider) || current_user.fleet_provider_admin? || current_user.fleet_provider_manager?
      redirect_to incidents_path, alert: "You are not authorized to update this incident."
      return
    end

    if @incident.update(incident_params)
      redirect_to @incident, notice: "Incident was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    unless current_user.fleet_providers.include?(@incident.fleet_provider) || current_user.fleet_provider_admin? || current_user.fleet_provider_manager?
      redirect_to incidents_path, alert: "You are not authorized to delete this incident."
      return
    end

    @incident.destroy
    redirect_to incidents_path, notice: "Incident was successfully deleted."
  end

  private

  def set_incident
    @incident = Incident.find(params[:id])
  end

  def incident_params
    base = params.require(:incident).permit(
      :fleet_provider_id,
      :incident_date,
      :incident_type,
      :damage_cost,
      :location,
      :report_reference,
      :description
    )

    base[:assigned_vehicle] = params.require(:assigned_vehicle).permit(:vehicle_id)
    base[:assigned_driver] = params.require(:assigned_driver).permit(:driver_id)

    base
  end
end
