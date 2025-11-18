class DevicesController < ApplicationController
  before_action :set_device, only: [ :edit, :update ]

  def new
    @device = Device.new(vehicle_id: params[:vehicle_id])
  end

  def create
    @device = Device.new(device_params)
    if @device.save
      redirect_to @device.vehicle || devices_path, notice: "GPS Device registered successfully"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @device.update(device_params)
      redirect_to @device.vehicle || devices_path, notice: "Device updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_device
    @device = Device.find(params[:id])
  end

  def device_params
    params.require(:device).permit(:terminal_id, :sim_number, :name, :vehicle_id, :status)
  end
end
