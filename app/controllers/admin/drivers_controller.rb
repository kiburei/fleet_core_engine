class Admin::DriversController < AdminController
  before_action :set_driver, only: [:show, :edit, :update, :destroy, :toggle_status]
  
  def index
    @drivers = Driver.includes(:user, :fleet_provider, :delivery_requests)
    
    # Filter by fleet provider if specified
    if params[:fleet_provider_id].present?
      @drivers = @drivers.where(fleet_provider_id: params[:fleet_provider_id])
    end
    
    # Filter by status if specified
    case params[:status]
    when 'online'
      @drivers = @drivers.where(is_online: true)
    when 'available'
      @drivers = @drivers.where(is_available_for_delivery: true)
    when 'busy'
      @drivers = @drivers.joins(:delivery_requests)
                         .where(delivery_requests: { status: ['assigned', 'picked_up', 'in_transit'] })
                         .distinct
    end
    
    @drivers = @drivers.order(:first_name, :last_name).page(params[:page])
    @fleet_providers = FleetProvider.all
    @stats = calculate_driver_stats
  end

  def show
    @recent_deliveries = @driver.delivery_requests
                               .recent
                               .includes(:marketplace_order, :customer)
                               .limit(20)
    @driver_stats = calculate_driver_individual_stats(@driver)
  end

  def new
    @driver = Driver.new
    @driver.build_user
    @fleet_providers = FleetProvider.delivery_enabled
  end

  def create
    @driver = Driver.new(driver_params)
    @fleet_providers = FleetProvider.delivery_enabled
    
    # Create user account for driver
    if user_params[:email].present?
      @user = User.find_by(email: user_params[:email])
      
      unless @user
        @user = User.new(user_params)
        @user.password = user_params[:password].presence || generate_password
        @user.password_confirmation = @user.password
        
        unless @user.save
          @driver.errors.add(:base, "User creation failed: #{@user.errors.full_messages.join(', ')}")
          render :new and return
        end
      end
      
      @driver.user = @user
    end

    if @driver.save
      # Assign driver role
      @user&.add_role(:fleet_provider_driver)
      
      flash[:notice] = "Driver #{@driver.full_name} was successfully created."
      redirect_to admin_driver_path(@driver)
    else
      render :new
    end
  end

  def edit
    @fleet_providers = FleetProvider.delivery_enabled
  end

  def update
    if @driver.update(driver_params)
      # Update user info if provided
      if @driver.user && user_update_params.any?
        @driver.user.update(user_update_params)
      end
      
      flash[:notice] = "Driver #{@driver.full_name} was successfully updated."
      redirect_to admin_driver_path(@driver)
    else
      @fleet_providers = FleetProvider.delivery_enabled
      render :edit
    end
  end

  def destroy
    name = @driver.full_name
    @driver.destroy
    flash[:notice] = "Driver #{name} was successfully deleted."
    redirect_to admin_drivers_path
  end

  def toggle_status
    case params[:action_type]
    when 'online'
      @driver.update(is_online: !@driver.is_online)
      status = @driver.is_online? ? 'online' : 'offline'
    when 'available'
      @driver.update(is_available_for_delivery: !@driver.is_available_for_delivery)
      status = @driver.is_available_for_delivery? ? 'available' : 'unavailable'
    end
    
    redirect_to admin_drivers_path, notice: "Driver is now #{status}"
  end

  private

  def set_driver
    @driver = Driver.find(params[:id])
  end

  def driver_params
    params.require(:driver).permit(
      :first_name, :middle_name, :last_name, :phone_number,
      :fleet_provider_id, :is_available_for_delivery, :max_delivery_distance_km,
      :profile_picture
    )
  end

  def user_params
    params.require(:driver).permit(
      user_attributes: [:email, :password, :first_name, :last_name, :phone]
    )[:user_attributes] || {}
  end

  def user_update_params
    params.require(:driver).permit(
      user_attributes: [:first_name, :last_name, :phone]
    )[:user_attributes] || {}
  end

  def generate_password
    SecureRandom.base64(12)
  end

  def calculate_driver_stats
    {
      total_drivers: Driver.count,
      online_drivers: Driver.where(is_online: true).count,
      available_drivers: Driver.where(is_available_for_delivery: true).count,
      busy_drivers: Driver.joins(:delivery_requests)
                          .where(delivery_requests: { status: ['assigned', 'picked_up', 'in_transit'] })
                          .distinct.count,
      total_deliveries_today: DeliveryRequest.where(created_at: Date.current.beginning_of_day..Date.current.end_of_day).count
    }
  end

  def calculate_driver_individual_stats(driver)
    today = Date.current
    {
      total_deliveries: driver.total_deliveries,
      today_deliveries: driver.delivery_requests.where(created_at: today.beginning_of_day..today.end_of_day).count,
      completed_deliveries: driver.delivery_requests.where(status: 'delivered').count,
      average_rating: driver.delivery_rating,
      total_earnings: driver.delivery_requests.where(status: 'delivered').sum(:driver_commission) || 0,
      today_earnings: driver.delivery_requests
                            .where(status: 'delivered', delivered_at: today.beginning_of_day..today.end_of_day)
                            .sum(:driver_commission) || 0
    }
  end
end