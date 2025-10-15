class DriversController < ApplicationController
  before_action :set_driver, only: %i[ show edit update destroy create_user_account reset_password deactivate_user reactivate_user ]

  # GET /drivers or /drivers.json
  def index
    @driver = Driver.new
    @per_page = params[:per_page] || 10
    @current_status = params[:status] || 'active'

    # Base query
    if params[:fleet_provider_id]
      @fleet_provider = FleetProvider.find(params[:fleet_provider_id])
      base_drivers = @fleet_provider.drivers.includes(:vehicle, :fleet_provider)
    else
      base_drivers = if current_user.admin?
                       Driver.all.includes(:vehicle, :fleet_provider)
                     else
                       Driver.where(fleet_provider_id: current_user.fleet_provider_ids).includes(:vehicle, :fleet_provider)
                     end
    end

    # Get all status counts for tabs
    @status_tabs = {
      'active' => {
        label: 'Active',
        count: base_drivers.where(license_status: 'active').count
      },
      'inactive' => {
        label: 'Inactive', 
        count: base_drivers.where(license_status: 'inactive').count
      },
      'suspended' => {
        label: 'Suspended',
        count: base_drivers.where(license_status: 'suspended').count
      }
    }
    
    @total_count = @status_tabs.values.sum { |tab| tab[:count] }
    @current_status = params[:status] || 'active'

    # Filter by status
    @drivers = if @current_status == 'all'
                 base_drivers
               else
                 base_drivers.where(license_status: @current_status)
               end

    # Apply search filter if present
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @drivers = @drivers.where(
        "first_name ILIKE ? OR last_name ILIKE ? OR license_number ILIKE ? OR phone_number ILIKE ?",
        search_term, search_term, search_term, search_term
      )
    end
    
    @drivers = @drivers.page(params[:page]).per(@per_page)
  end

  # GET /drivers/1 or /drivers/1.json
  def show
    unless current_user.fleet_providers.include?(@driver.fleet_provider) || current_user.admin?
      redirect_to drivers_path, alert: "You are not authorized to view this driver."
      nil
    end
  end

  # GET /drivers/new
  def new
    unless current_user.fleet_provider_admin? || current_user.fleet_provider_manager?
      redirect_to drivers_path, alert: "You are not authorized to create drivers."
      return
    end
    @driver = Driver.new
  end

  # GET /drivers/1/edit
  def edit
    unless current_user.fleet_providers.include?(@driver.fleet_provider) || current_user.fleet_provider_admin? || current_user.fleet_provider_manager?
      redirect_to drivers_path, alert: "You are not authorized to edit this driver."
      nil
    end
  end

  # POST /drivers or /drivers.json
  def create
    # only fleet provider admin can and fleet provider manager can create drivers
    unless current_user.fleet_provider_admin? || current_user.fleet_provider_manager?
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
    unless current_user.fleet_providers.include?(@driver.fleet_provider) || current_user.fleet_provider_admin? || current_user.fleet_provider_manager?
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
    unless current_user.fleet_providers.include?(@driver.fleet_provider) || current_user.fleet_provider_admin? || current_user.fleet_provider_manager?
      redirect_to drivers_path, alert: "You are not authorized to destroy this driver."
      return
    end

    @driver.destroy!

    respond_to do |format|
      format.html { redirect_to drivers_path, status: :see_other, notice: "Driver was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  # POST /drivers/:id/create_user_account
  def create_user_account
    unless current_user.fleet_provider_admin? || current_user.fleet_provider_manager?
      redirect_to @driver, alert: "You are not authorized to create user accounts."
      return
    end

    if @driver.has_user_account?
      redirect_to @driver, alert: "Driver already has a user account."
      return
    end

    begin
      user = @driver.create_user_account!
      @driver.send_login_credentials
      
      flash[:notice] = "User account created successfully for #{@driver.full_name}."
      flash[:info] = "Login credentials: Email: #{user.email}, Temporary Password: #{@driver.temporary_password}"
      
    rescue ActiveRecord::RecordInvalid => e
      flash[:alert] = "Failed to create user account: #{e.message}"
    rescue => e
      flash[:alert] = "An error occurred while creating the user account: #{e.message}"
    end

    redirect_to @driver
  end

  # PATCH /drivers/:id/reset_password
  def reset_password
    unless current_user.fleet_provider_admin? || current_user.fleet_provider_manager?
      redirect_to @driver, alert: "You are not authorized to reset passwords."
      return
    end

    unless @driver.has_user_account?
      redirect_to @driver, alert: "Driver does not have a user account."
      return
    end

    begin
      new_password = @driver.reset_password!
      
      flash[:notice] = "Password reset successfully for #{@driver.full_name}."
      flash[:info] = "New temporary password: #{new_password}"
      
    rescue => e
      flash[:alert] = "Failed to reset password: #{e.message}"
    end

    redirect_to @driver
  end

  # PATCH /drivers/:id/deactivate_user
  def deactivate_user
    unless current_user.fleet_provider_admin? || current_user.fleet_provider_manager?
      redirect_to @driver, alert: "You are not authorized to deactivate user accounts."
      return
    end

    unless @driver.has_user_account?
      redirect_to @driver, alert: "Driver does not have a user account."
      return
    end

    begin
      @driver.deactivate_user_account!
      flash[:notice] = "User account deactivated for #{@driver.full_name}."
      
    rescue => e
      flash[:alert] = "Failed to deactivate user account: #{e.message}"
    end

    redirect_to @driver
  end

  # PATCH /drivers/:id/reactivate_user
  def reactivate_user
    unless current_user.fleet_provider_admin? || current_user.fleet_provider_manager?
      redirect_to @driver, alert: "You are not authorized to reactivate user accounts."
      return
    end

    unless @driver.has_user_account?
      redirect_to @driver, alert: "Driver does not have a user account."
      return
    end

    begin
      @driver.reactivate_user_account!
      flash[:notice] = "User account reactivated for #{@driver.full_name}."
      
    rescue => e
      flash[:alert] = "Failed to reactivate user account: #{e.message}"
    end

    redirect_to @driver
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_driver
      @driver = Driver.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def driver_params
      params.expect(driver: [ :first_name, :middle_name, :last_name, :license_number, :phone_number, :vehicle_id, :profile_picture, :fleet_provider_id, :email, :create_user_account ])
    end
end
