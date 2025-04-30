class DriversController < ApplicationController
  before_action :set_driver, only: %i[ show edit update destroy ]

  # GET /drivers or /drivers.json
  def index
    @driver = Driver.new

    if params[:fleet_provider_id]
      @fleet_provider = FleetProvider.find(params[:fleet_provider_id])
      @drivers = @fleet_provider.drivers.includes(:vehicle)
    else
      @drivers = if current_user.admin?
                    Driver.all.includes(:vehicle)
      else
                    Driver.where(fleet_provider_id: current_user.fleet_provider_id).includes(:vehicle)
      end
    end
  end

  # GET /drivers/1 or /drivers/1.json
  def show
    if current_user.fleet_provider_id != @driver.fleet_provider_id && !current_user.admin?
      redirect_to drivers_path, alert: "You are not authorized to view this driver."
      nil
    end
  end

  # GET /drivers/new
  def new
    if !current_user.fleet_provider_admin? || !current_user.fleet_provider_manager?
      redirect_to drivers_path, alert: "You are not authorized to create drivers."
      return
    end
    @driver = Driver.new
  end

  # GET /drivers/1/edit
  def edit
    if current_user.fleet_provider_id != @driver.fleet_provider_id && !current_user.fleet_provider_admin? || !current_user.fleet_provider_manager?
      redirect_to drivers_path, alert: "You are not authorized to edit this driver."
      nil
    end
  end

  # POST /drivers or /drivers.json
  def create
    # only fleet provider admin can and fleet provider manager can create drivers
    if !current_user.fleet_provider_admin? || !current_user.fleet_provider_manager?
      redirect_to drivers_path, alert: "You are not authorized to create drivers."
      return
    end

    @driver = Driver.new(driver_params)

    respond_to do |format|
      if @driver.save
        format.html { redirect_to @driver, notice: "Driver was successfully created." }
        format.json { render :show, status: :created, location: @driver }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @driver.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /drivers/1 or /drivers/1.json
  def update
    if current_user.fleet_provider_id != @driver.fleet_provider_id && !current_user.fleet_provider_admin? || !current_user.fleet_provider_manager?
      redirect_to drivers_path, alert: "You are not authorized to update this driver."
      return
    end

    respond_to do |format|
      if @driver.update(driver_params)
        format.html { redirect_to @driver, notice: "Driver was successfully updated." }
        format.json { render :show, status: :ok, location: @driver }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @driver.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /drivers/1 or /drivers/1.json
  def destroy
    if current_user.fleet_provider_id != @driver.fleet_provider_id && !current_user.fleet_provider_admin? || !current_user.fleet_provider_manager?
      redirect_to drivers_path, alert: "You are not authorized to destroy this driver."
      return
    end

    @driver.destroy!

    respond_to do |format|
      format.html { redirect_to drivers_path, status: :see_other, notice: "Driver was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_driver
      @driver = Driver.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def driver_params
      params.expect(driver: [ :first_name, :middle_name, :last_name, :license_number, :phone_number, :vehicle_id, :fleet_provider_id ])
    end
end
