class DevicesController < ApplicationController
  before_action :set_device, only: [ :show, :edit, :update ]
  before_action :set_device, only: [ :show, :edit, :update, :ping ]

  def new
    @device = Device.new(vehicle_id: params[:vehicle_id])
  end

  def show
    # set_device will load @device
  end

  def ping
    # Try exact terminal id and normalized numeric-only id
    socket = Jt808::Registry.get_socket(@device.terminal_id)

    if socket.nil?
      numeric = @device.terminal_id.to_s.gsub(/[^0-9]/, "")
      socket = Jt808::Registry.get_socket(numeric)
    end

    # Also try sim_number if terminal_id didn't match
    if socket.nil? && @device.sim_number.present?
      socket = Jt808::Registry.get_socket(@device.sim_number)
      if socket.nil?
        numeric = @device.sim_number.to_s.gsub(/[^0-9]/, "")
        socket = Jt808::Registry.get_socket(numeric)
      end
    end

    if socket
      begin
        socket.write("PING\n")
        flash[:notice] = "Ping sent to device #{@device.terminal_id}"
      rescue => e
        Rails.logger.error "Failed to ping device: #{e.message}"
        flash[:alert] = "Failed to send ping: #{e.message}"
      end
    else
      flash[:alert] = "Device #{@device.terminal_id} is not connected. Check that terminal_id or sim_number matches the device's phone number."
    end

    redirect_back fallback_location: device_path(@device)
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
