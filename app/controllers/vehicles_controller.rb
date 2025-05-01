class VehiclesController < ApplicationController
  before_action :set_vehicle, only: %i[ show edit update destroy ]

  # GET /vehicles or /vehicles.json
  def index
    @vehicle = Vehicle.new

    if params[:fleet_provider_id]
      @fleet_provider = FleetProvider.find(params[:fleet_provider_id])
      @vehicles = @fleet_provider.vehicles.includes(:vehicle_model)
    else
      @vehicles = if current_user.admin?
                   Vehicle.all.includes(:vehicle_model)
      elsif current_user.fleet_provider_admin? || current_user.fleet_provider_manager?
                   Vehicle.where(fleet_provider_id: current_user.fleet_provider_ids).includes(:vehicle_model)
      end
    end
  end

  # GET /vehicles/1 or /vehicles/1.json
  def show
    unless current_user.fleet_providers.include?(@vehicle.fleet_provider) || current_user.admin?
      redirect_to vehicles_path, alert: "You are not authorized to view this vehicle."
      nil
    end
  end

  # GET /vehicles/new
  def new
    unless current_user.fleet_provider_admin? || current_user.fleet_provider_manager?
      redirect_to vehicles_path, alert: "You are not authorized to create vehicles."
      return
    end
    @vehicle = Vehicle.new
  end

  # GET /vehicles/1/edit
  def edit
    unless current_user.fleet_providers.include?(@fleet_provider) || current_user.fleet_provider_admin? || current_user.fleet_provider_manager?
      redirect_to vehicles_path, alert: "You are not authorized to edit this vehicle."
      nil
    end
  end

  # POST /vehicles or /vehicles.json
  def create
    # only fleet provider admin can and fleet provider manager can create vehicles
    unless current_user.fleet_provider_admin? || current_user.fleet_provider_manager?
      redirect_to vehicles_path, alert: "You are not authorized to create vehicles."
      return
    end

    @vehicle = Vehicle.new(vehicle_params)

    respond_to do |format|
      if @vehicle.save
        format.html { redirect_to @vehicle, notice: "Vehicle was successfully created." }
        format.json { render :show, status: :created, location: @vehicle }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @vehicle.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /vehicles/1 or /vehicles/1.json
  def update
    unless current_user.fleet_providers.include?(@fleet_provider) || current_user.fleet_provider_admin? || current_user.fleet_provider_manager?
      redirect_to vehicles_path, alert: "You are not authorized to update this vehicle."
      return
    end

    respond_to do |format|
      if @vehicle.update(vehicle_params)
        format.html { redirect_to @vehicle, notice: "Vehicle was successfully updated." }
        format.json { render :show, status: :ok, location: @vehicle }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @vehicle.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /vehicles/1 or /vehicles/1.json
  def destroy
    unless current_user.fleet_providers.include?(@fleet_provider) || current_user.fleet_provider_admin? || current_user.fleet_provider_manager?
      redirect_to vehicles_path, alert: "You are not authorized to destroy this vehicle."
      return
    end
    @vehicle.destroy!

    respond_to do |format|
      format.html { redirect_to vehicles_path, status: :see_other, notice: "Vehicle was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_vehicle
      @vehicle = Vehicle.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def vehicle_params
      params.expect(vehicle: [ :vehicle_model_id, :registration_number, :status, :fleet_provider_id ])
    end
end
