class TripsController < ApplicationController
  before_action :set_trip, only: %i[ show edit update destroy ]

  # GET /trips or /trips.json
  def index
    @trip = Trip.new

    if params[:fleet_provider_id]
      @fleet_provider = FleetProvider.find(params[:fleet_provider_id])
      @trips = @fleet_provider.trips.includes(:vehicle, :driver)
    else
      @trips = if current_user.admin?
                 Trip.all.includes(:vehicle, :driver)
      else
                 Trip.where(fleet_provider_id: current_user.fleet_provider_id).includes(:vehicle, :driver)
      end
    end
  end

  # GET /trips/1 or /trips/1.json
  def show
    if current_user.fleet_provider_id != @trip.fleet_provider_id && !current_user.admin?
      redirect_to trips_path, alert: "You are not authorized to view this trip."
      nil
    end

    @manifest = @trip.manifest || @trip.build_manifest
    1.times { @manifest.manifest_items.build } if @manifest.manifest_items.empty?
  end

  # GET /trips/new
  def new
    if !current_user.fleet_provider_admin? || !current_user.fleet_provider_manager? || !current_user.fleet_provider_driver? || !current_user.fleet_provider_user?
      redirect_to trips_path, alert: "You are not authorized to create trips."
      return
    end
    @trip = Trip.new
  end

  # GET /trips/1/edit
  def edit
    if current_user.fleet_provider_id != @trip.fleet_provider_id && !current_user.fleet_provider_admin? || !current_user.fleet_provider_manager?
      redirect_to trips_path, alert: "You are not authorized to edit this trip."
      nil
    end
  end

  # POST /trips or /trips.json
  def create
    # only fleet provider admin can and fleet provider manager can create trips and fleet provider user can create trips
    if !current_user.fleet_provider_admin? || !current_user.fleet_provider_manager? || !current_user.fleet_provider_user?
      redirect_to trips_path, alert: "You are not authorized to create trips."
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
    if current_user.fleet_provider_id != @trip.fleet_provider_id && !current_user.fleet_provider_admin? || !current_user.fleet_provider_manager?
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
    if current_user.fleet_provider_id != @trip.fleet_provider_id && !current_user.fleet_provider_admin? || !current_user.fleet_provider_manager?
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
      params.expect(trip: [ :fleet_provider_id, :vehicle_id, :driver_id, :origin, :destination, :departure_time, :arrival_time, :status ])
    end
end
