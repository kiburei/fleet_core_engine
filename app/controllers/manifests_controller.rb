class ManifestsController < ApplicationController
  before_action :set_trip

  def show
    @manifest = @trip.manifest
  end

  def new
    @manifest = @trip.build_manifest
    3.times { @manifest.manifest_items.build } # you can adjust based on use-case
  end

  def create
    @manifest = @trip.build_manifest(manifest_params)
    if @manifest.save
      @trip.update(status: "active")
      redirect_to trip_manifest_path(@trip), notice: "Manifest successfully created. Trip is now active."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def edit
    @manifest = @trip.manifest
  end

  def update
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
