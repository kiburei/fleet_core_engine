class MaintenancesController < ApplicationController
  before_action :set_maintenance, only: %i[edit update destroy show]

  def index
    @maintenances = Maintenance.all
    @maintenance = Maintenance.new
  end

  def new
    @maintenance = Maintenance.new
  end

  def show
  end

  def create
    @maintenance = Maintenance.new(maintenance_params)
    if @maintenance.save
      redirect_to maintenance_path(@maintenance), notice: "Maintenance record added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @maintenance.update(maintenance_params)
      redirect_to vehicle_path(@vehicle), notice: "Maintenance record updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @maintenance.destroy
    redirect_to vehicle_path(@vehicle), notice: "Maintenance record removed."
  end

  private

  def set_maintenance
    @maintenance = Maintenance.find(params[:id])
  end

  def maintenance_params
    params.require(:maintenance).permit(:vehicle_id, :maintenance_type, :description, :maintenance_date, :maintenance_cost, :service_provider, :odometer, :next_service_due)
  end
end
