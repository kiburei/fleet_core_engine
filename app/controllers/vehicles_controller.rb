class VehiclesController < ApplicationController
  before_action :set_vehicle, only: %i[ show edit update destroy ]

  # GET /vehicles or /vehicles.json
  def index
    @vehicle = Vehicle.new
    @per_page = params[:per_page] || 10
    @current_status = params[:status] || "active"

    begin
      # Base query
      if params[:fleet_provider_id]
        @fleet_provider = FleetProvider.find(params[:fleet_provider_id])
        base_vehicles = @fleet_provider.vehicles.includes(:vehicle_model, :fleet_provider)
      else
        base_vehicles = if current_user&.admin?
                          Vehicle.all.includes(:vehicle_model, :fleet_provider)
        elsif current_user&.fleet_provider_admin? || current_user&.fleet_provider_manager?
                          Vehicle.where(fleet_provider_id: current_user.fleet_provider_ids).includes(:vehicle_model, :fleet_provider)
        else
                          # Fallback if no user or permissions
                          Vehicle.none
        end
      end

      # Get all status counts for tabs
      @status_tabs = {
        "active" => {
          label: "Active",
          count: base_vehicles.where(status: "active").count
        },
        "inactive" => {
          label: "Inactive",
          count: base_vehicles.where(status: "inactive").count
        },
        "maintenance" => {
          label: "Maintenance",
          count: base_vehicles.where(status: "maintenance").count
        }
      }

      @total_count = @status_tabs.values.sum { |tab| tab[:count] }
      @current_status = params[:status] || "active"

      # Filter by status
      @vehicles = if @current_status == "all"
                    base_vehicles
      else
                    base_vehicles.where(status: @current_status)
      end

      # Apply search filter if present
      if params[:search].present?
        search_term = "%#{params[:search]}%"
        @vehicles = @vehicles.joins(:vehicle_model).where(
          "vehicles.registration_number ILIKE ? OR vehicle_models.make ILIKE ? OR vehicle_models.model ILIKE ?",
          search_term, search_term, search_term
        )
      end

      @vehicles = @vehicles.page(params[:page]).per(@per_page)
    rescue => e
      # Error fallback
      Rails.logger.error "VehiclesController#index error: #{e.message}"
      @status_tabs = {
        "active" => { label: "Active", count: 0 },
        "inactive" => { label: "Inactive", count: 0 },
        "maintenance" => { label: "Maintenance", count: 0 }
      }
      @total_count = 0
      @current_status = "active"
      @vehicles = Vehicle.none.page(params[:page]).per(@per_page)
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
    unless current_user.fleet_providers.include?(@vehicle.fleet_provider) || current_user.fleet_provider_admin? || current_user.fleet_provider_manager?
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
    unless current_user.fleet_providers.include?(@vehicle.fleet_provider) || current_user.fleet_provider_admin? || current_user.fleet_provider_manager?
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
      @vehicle = Vehicle.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def vehicle_params
      params.require(:vehicle).permit(:vehicle_model_id, :registration_number, :status, :fleet_provider_id, :logo)
    end
end
