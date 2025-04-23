class IncidentsController < ApplicationController
  before_action :set_incident, only: %i[show edit update destroy]

  def index
    @incidents = Incident.includes(:vehicle, :driver).order(incident_date: :desc)
    @incident = Incident.new
  end

  def show
  end

  def new
    @incident = Incident.new
  end

  def edit
  end

  def create
    @incident = Incident.new(incident_params)
    if @incident.save
      redirect_to @incident, notice: "Incident was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @incident.update(incident_params)
      redirect_to @incident, notice: "Incident was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @incident.destroy
    redirect_to incidents_path, notice: "Incident was successfully deleted."
  end

  private

  def set_incident
    @incident = Incident.find(params[:id])
  end

  def incident_params
    params.require(:incident).permit(:vehicle_id, :driver_id, :incident_date, :incident_type, :damage_cost, :location, :report_reference, :description)
  end
end
