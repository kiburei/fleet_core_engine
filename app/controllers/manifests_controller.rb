class ManifestsController < ApplicationController
  before_action :set_trip

  def show
    if current_user.fleet_provider_id != @trip.fleet_provider_id && !current_user.admin?
      redirect_to trips_path, alert: "You are not authorized to view this trip."
      return
    end
    @manifest = @trip.manifest
  end

  def new
    if current_user.fleet_provider_id != @trip.fleet_provider_id && !current_user.fleet_provider_admin? || !current_user.fleet_provider_manager? || !current_user.fleet_provider_user?
      redirect_to trips_path, alert: "You are not authorized to create a manifest."
      return
    end

    @manifest = @trip.build_manifest
    3.times { @manifest.manifest_items.build } # you can adjust based on use-case
  end

  def create
    if current_user.fleet_provider_id != @trip.fleet_provider_id && !current_user.fleet_provider_admin? || !current_user.fleet_provider_manager? || !current_user.fleet_provider_user?
      redirect_to trips_path, alert: "You are not authorized to create a manifest."
      return
    end

    @manifest = @trip.build_manifest(manifest_params)
    if @manifest.save
      @trip.update(status: "active")
      redirect_to trip_manifest_path(@trip), notice: "Manifest successfully created. Trip is now active."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def edit
    if current_user.fleet_provider_id != @trip.fleet_provider_id && !current_user.fleet_provider_admin? || !current_user.fleet_provider_manager?
      redirect_to trips_path, alert: "You are not authorized to edit this manifest."
      return
    end


    @manifest = @trip.manifest
  end

  def update
    if current_user.fleet_provider_id != @trip.fleet_provider_id && !current_user.fleet_provider_admin? || !current_user.fleet_provider_manager?
      redirect_to trips_path, alert: "You are not authorized to update this manifest."
      return
    end

    @manifest = @trip.manifest
    if @manifest.update(manifest_params)
      redirect_to trip_manifest_path(@trip), notice: "Manifest updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_trip
    @trip = Trip.find(params[:trip_id])
  end

  def manifest_params
    params.require(:manifest).permit(
      :notes,
      manifest_items_attributes: [ :id, :item_type, :description, :quantity, :unit, :category, :_destroy ]
    )
  end
end
