class TripsController < ApplicationController
  before_action :set_trip, only: %i[ show edit update destroy ]

  # GET /trips or /trips.json
  def index
    @trip = Trip.new
    @per_page = params[:per_page] || 10

    if params[:fleet_provider_id]
      @fleet_provider = FleetProvider.find(params[:fleet_provider_id])
      @trips = @fleet_provider.trips.includes(:vehicle, :driver)
    else
      @trips = if current_user.admin?
                 Trip.all.includes(:vehicle, :driver)
      else
                 Trip.where(fleet_provider_id: current_user.fleet_provider_ids).includes(:vehicle, :driver)
      end
    end
    
    @trips = @trips.page(params[:page]).per(@per_page)
  end

  # GET /trips/1 or /trips/1.json
  def show
    unless current_user.fleet_providers.include?(@trip.fleet_provider) || current_user.admin?
      redirect_to trips_path, alert: "You are not authorized to view this trip."
      nil
    end

    @manifest = @trip.manifest || @trip.build_manifest
    1.times { @manifest.manifest_items.build } if @manifest.manifest_items.empty?
  end

  # GET /trips/new
  def new
    unless current_user.fleet_provider_admin? || current_user.fleet_provider_manager?
      redirect_to trips_path, alert: "You are not authorized to create trips."
      return
    end
    @trip = Trip.new
  end

  # GET /trips/1/edit
  def edit
    unless current_user.fleet_providers.include?(@trip.fleet_provider) || current_user.fleet_provider_admin? || current_user.fleet_provider_manager?
      redirect_to trips_path, alert: "You are not authorized to edit this trip."
      nil
    end
  end

  # POST /trips or /trips.json
  def create
    # only fleet provider admin can and fleet provider manager can create trips and fleet provider user can create trips
    unless current_user.fleet_provider_admin? || current_user.fleet_provider_manager?
      redirect_to trips_path, alert: "You are not authorized to create trips."
      return
    end

    # check if trip already exists for the same vehicle or driver and is not completed
    vehicle_id = params.dig(:assigned_vehicle, :vehicle_id)
    driver_id  = params.dig(:assigned_driver, :driver_id)

    if Trip.where(status: %w[scheduled in_progress])
          .where("vehicle_id = :v_id OR driver_id = :d_id", v_id: vehicle_id, d_id: driver_id)
          .exists?
      redirect_to trips_path, alert: "A trip already exists for this vehicle or driver that is not completed or cancelled."
      return
    end

    @trip = Trip.new(trip_params)

    respond_to do |format|
      if @trip.save
        format.html { redirect_to @trip, notice: "Trip was successfully created." }
        format.json { render :show, status: :created, location: @trip }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @trip.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /trips/1 or /trips/1.json
  def update
    unless current_user.fleet_providers.include?(@trip.fleet_provider) || current_user.fleet_provider_admin? || current_user.fleet_provider_manager?
      redirect_to trips_path, alert: "You are not authorized to update this trip."
      return
    end
    respond_to do |format|
      if @trip.update(trip_params)
        format.html { redirect_to @trip, notice: "Trip was successfully updated." }
        format.json { render :show, status: :ok, location: @trip }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @trip.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /trips/1 or /trips/1.json
  def destroy
    unless current_user.fleet_providers.include?(@trip.fleet_provider) || current_user.fleet_provider_admin? || current_user.fleet_provider_manager?
      redirect_to trips_path, alert: "You are not authorized to destroy this trip."
      return
    end
    @trip.destroy!

    respond_to do |format|
      format.html { redirect_to trips_path, status: :see_other, notice: "Trip was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_trip
      @trip = Trip.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def trip_params
      base = params.require(:trip).permit(
        :fleet_provider_id,
        :origin,
        :destination,
        :departure_time,
        :arrival_time,
        :status,
        :trackable,
        :has_manifest
      )

      base[:assigned_vehicle] = params.require(:assigned_vehicle).permit(:vehicle_id)
      base[:assigned_driver] = params.require(:assigned_driver).permit(:driver_id)

      base
    end
end
