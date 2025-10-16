class DeliveryRequestsController < ApplicationController
  before_action :set_delivery_request, only: [:show, :edit, :update, :destroy, :assign_driver, :cancel_delivery, :auto_dispatch]
  
  def index
    # Scope delivery requests based on user permissions
    @delivery_requests = if current_user.admin?
                          DeliveryRequest.includes(:driver, :business_customer, :fleet_provider, :marketplace_order)
                        else
                          DeliveryRequest.where(fleet_provider_id: current_user.fleet_provider_ids)
                                        .includes(:driver, :business_customer, :fleet_provider, :marketplace_order)
                        end
    
    # Filter by status if specified
    if params[:status].present?
      @delivery_requests = @delivery_requests.where(status: params[:status])
    end
    
    # Filter by fleet provider if specified
    if params[:fleet_provider_id].present?
      @delivery_requests = @delivery_requests.where(fleet_provider_id: params[:fleet_provider_id])
    end
    
    # Filter by driver if specified
    if params[:driver_id].present?
      @delivery_requests = @delivery_requests.where(driver_id: params[:driver_id])
    end
    
    # Filter by date range
    if params[:date_from].present?
      @delivery_requests = @delivery_requests.where('requested_at >= ?', Date.parse(params[:date_from]).beginning_of_day)
    end
    
    if params[:date_to].present?
      @delivery_requests = @delivery_requests.where('requested_at <= ?', Date.parse(params[:date_to]).end_of_day)
    end
    
    @delivery_requests = @delivery_requests.recent.page(params[:page])
    
    # Scope fleet providers and drivers based on user permissions
    @fleet_providers = if current_user.admin?
                        FleetProvider.all
                      else
                        current_user.fleet_providers
                      end
    
    @drivers = if current_user.admin?
                Driver.includes(:fleet_provider).order(:first_name, :last_name)
              else
                Driver.where(fleet_provider_id: current_user.fleet_provider_ids)
                      .includes(:fleet_provider).order(:first_name, :last_name)
              end
              
    @stats = calculate_delivery_stats
  end

  def show
    # Check authorization for non-admin users
    unless current_user.admin? || current_user.fleet_provider_ids.include?(@delivery_request.fleet_provider_id)
      redirect_to delivery_requests_path, alert: "You are not authorized to view this delivery request."
      return
    end
    
    @timeline = build_delivery_timeline(@delivery_request)
    @available_drivers = find_available_drivers_for_delivery(@delivery_request) if @delivery_request.can_be_assigned?
  end

  def new
    @delivery_request = DeliveryRequest.new
    @customers = Customer.active.order(:business_name)
    # Scope fleet providers based on user permissions
    @fleet_providers = if current_user.admin?
                        FleetProvider.all
                      else
                        current_user.fleet_providers
                      end
    # Scope drivers based on user permissions
    @drivers = if current_user.admin?
                Driver.includes(:fleet_provider).order(:first_name, :last_name)
              else
                Driver.where(fleet_provider_id: current_user.fleet_provider_ids)
                      .includes(:fleet_provider).order(:first_name, :last_name)
              end
  end

  def create
    @delivery_request = DeliveryRequest.new(delivery_request_params)
    
    # Create marketplace order if it doesn't exist
    unless @delivery_request.marketplace_order
      order = create_marketplace_order
      @delivery_request.marketplace_order = order
    end
    
    if @delivery_request.save
      # Auto-assign driver if specified
      if params[:auto_assign] == '1' && params[:driver_id].present?
        driver = Driver.find(params[:driver_id])
        @delivery_request.assign_to_driver!(driver) if driver.can_accept_delivery?(@delivery_request)
      elsif params[:auto_dispatch] == '1'
        DeliveryDispatchJob.perform_later(@delivery_request.id)
      end
      
      flash[:notice] = "Delivery request #{@delivery_request.request_number} was successfully created."
      redirect_to delivery_request_path(@delivery_request)
    else
      @customers = Customer.active.order(:business_name)
      # Scope fleet providers based on user permissions
      @fleet_providers = if current_user.admin?
                          FleetProvider.all
                        else
                          current_user.fleet_providers
                        end
      # Scope drivers based on user permissions
      @drivers = if current_user.admin?
                  Driver.includes(:fleet_provider).order(:first_name, :last_name)
                else
                  Driver.where(fleet_provider_id: current_user.fleet_provider_ids)
                        .includes(:fleet_provider).order(:first_name, :last_name)
                end
      render :new
    end
  end

  def edit
    # Check authorization for non-admin users
    unless current_user.admin? || current_user.fleet_provider_ids.include?(@delivery_request.fleet_provider_id)
      redirect_to delivery_requests_path, alert: "You are not authorized to edit this delivery request."
      return
    end
    
    @customers = Customer.active.order(:business_name)
    # Scope fleet providers based on user permissions
    @fleet_providers = if current_user.admin?
                        FleetProvider.all
                      else
                        current_user.fleet_providers
                      end
    # Scope drivers based on user permissions
    @drivers = if current_user.admin?
                Driver.includes(:fleet_provider).order(:first_name, :last_name)
              else
                Driver.where(fleet_provider_id: current_user.fleet_provider_ids)
                      .includes(:fleet_provider).order(:first_name, :last_name)
              end
  end

  def update
    # Check authorization for non-admin users
    unless current_user.admin? || current_user.fleet_provider_ids.include?(@delivery_request.fleet_provider_id)
      redirect_to delivery_requests_path, alert: "You are not authorized to update this delivery request."
      return
    end
    
    if @delivery_request.update(delivery_request_params)
      flash[:notice] = "Delivery request #{@delivery_request.request_number} was successfully updated."
      redirect_to delivery_request_path(@delivery_request)
    else
      @customers = Customer.active.order(:business_name)
      # Scope fleet providers based on user permissions
      @fleet_providers = if current_user.admin?
                          FleetProvider.all
                        else
                          current_user.fleet_providers
                        end
      # Scope drivers based on user permissions
      @drivers = if current_user.admin?
                  Driver.includes(:fleet_provider).order(:first_name, :last_name)
                else
                  Driver.where(fleet_provider_id: current_user.fleet_provider_ids)
                        .includes(:fleet_provider).order(:first_name, :last_name)
                end
      render :edit
    end
  end

  def destroy
    # Check authorization for non-admin users
    unless current_user.admin? || current_user.fleet_provider_ids.include?(@delivery_request.fleet_provider_id)
      redirect_to delivery_requests_path, alert: "You are not authorized to delete this delivery request."
      return
    end
    
    request_number = @delivery_request.request_number
    @delivery_request.destroy
    flash[:notice] = "Delivery request #{request_number} was successfully deleted."
    redirect_to delivery_requests_path
  end

  def assign_driver
    # Check authorization for non-admin users
    unless current_user.admin? || current_user.fleet_provider_ids.include?(@delivery_request.fleet_provider_id)
      redirect_to delivery_requests_path, alert: "You are not authorized to assign drivers to this delivery request."
      return
    end
    
    driver = Driver.find(params[:driver_id])
    
    if driver.can_accept_delivery?(@delivery_request)
      @delivery_request.assign_to_driver!(driver)
      flash[:notice] = "Delivery assigned to #{driver.full_name}"
    else
      flash[:alert] = "Cannot assign delivery to #{driver.full_name}. Driver may not be available or outside service area."
    end
    
    redirect_to delivery_request_path(@delivery_request)
  end

  def cancel_delivery
    # Check authorization for non-admin users
    unless current_user.admin? || current_user.fleet_provider_ids.include?(@delivery_request.fleet_provider_id)
      redirect_to delivery_requests_path, alert: "You are not authorized to cancel this delivery request."
      return
    end
    
    reason = params[:cancellation_reason] || 'Cancelled by user'
    @delivery_request.cancel!(reason)
    flash[:notice] = "Delivery request was cancelled."
    redirect_to delivery_request_path(@delivery_request)
  end

  def auto_dispatch
    # Check authorization for non-admin users
    unless current_user.admin? || current_user.fleet_provider_ids.include?(@delivery_request.fleet_provider_id)
      redirect_to delivery_requests_path, alert: "You are not authorized to dispatch this delivery request."
      return
    end
    
    if @delivery_request.can_be_assigned?
      DeliveryDispatchJob.perform_later(@delivery_request.id)
      flash[:notice] = "Delivery has been dispatched to available drivers."
    else
      flash[:alert] = "Cannot dispatch this delivery. It may already be assigned or completed."
    end
    redirect_to delivery_request_path(@delivery_request)
  end

  def bulk_actions
    delivery_ids = params[:delivery_ids] || []
    action = params[:bulk_action]
    
    case action
    when 'auto_dispatch'
      delivery_ids.each do |id|
        delivery = DeliveryRequest.find(id)
        DeliveryDispatchJob.perform_later(delivery.id) if delivery.can_be_assigned?
      end
      flash[:notice] = "#{delivery_ids.count} deliveries dispatched for assignment"
      
    when 'cancel'
      reason = params[:cancellation_reason] || 'Bulk cancelled'
      cancelled_count = 0
      delivery_ids.each do |id|
        delivery = DeliveryRequest.find(id)
        if delivery.can_be_cancelled?
          delivery.cancel!(reason)
          cancelled_count += 1
        end
      end
      flash[:notice] = "#{cancelled_count} deliveries cancelled"
      
    when 'change_fleet'
      fleet_provider = FleetProvider.find(params[:new_fleet_provider_id])
      updated_count = 0
      delivery_ids.each do |id|
        delivery = DeliveryRequest.find(id)
        if delivery.pending?
          delivery.update(fleet_provider: fleet_provider)
          updated_count += 1
        end
      end
      flash[:notice] = "#{updated_count} deliveries moved to #{fleet_provider.name}"
    end
    
    redirect_to delivery_requests_path
  end

  def analytics
    @date_range = params[:date_range] || '7'
    start_date = @date_range.to_i.days.ago.beginning_of_day
    end_date = Time.current.end_of_day
    
    @analytics_data = {
      total_deliveries: DeliveryRequest.where(created_at: start_date..end_date).count,
      completed_deliveries: DeliveryRequest.where(status: 'delivered', delivered_at: start_date..end_date).count,
      cancelled_deliveries: DeliveryRequest.where(status: 'cancelled', cancelled_at: start_date..end_date).count,
      active_deliveries: DeliveryRequest.where(status: ['assigned', 'picked_up', 'in_transit']).count,
      average_delivery_time: calculate_average_delivery_time(start_date, end_date),
      total_revenue: DeliveryRequest.where(status: 'delivered', delivered_at: start_date..end_date).sum(:delivery_fee),
      driver_earnings: DeliveryRequest.where(status: 'delivered', delivered_at: start_date..end_date).sum(:driver_commission),
      top_drivers: top_performing_drivers(start_date, end_date),
      deliveries_by_day: deliveries_by_day(start_date, end_date),
      deliveries_by_status: deliveries_by_status(start_date, end_date)
    }
  end

  private

  def set_delivery_request
    @delivery_request = DeliveryRequest.find(params[:id])
  end

  def delivery_request_params
    params.require(:delivery_request).permit(
      :business_customer_id, :fleet_provider_id, :pickup_address, :pickup_latitude, :pickup_longitude,
      :pickup_instructions, :pickup_contact_name, :pickup_contact_phone,
      :delivery_address, :delivery_latitude, :delivery_longitude,
      :delivery_instructions, :delivery_contact_name, :delivery_contact_phone,
      :delivery_fee, :priority, :estimated_distance_km, :estimated_duration_minutes,
      :end_customer_name, :end_customer_phone, :end_customer_email,
      :order_value, :order_items_count, :payment_method, :special_instructions
    )
  end

  def create_marketplace_order
    customer = Customer.find(delivery_request_params[:business_customer_id])
    Marketplace::Order.create!(
      user: customer.account_manager || current_user, # Use current user as fallback instead of first user
      order_number: "DEL-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(3).upcase}",
      total_amount: delivery_request_params[:order_value]&.to_f || 0.0,
      status: :pending,
      payment_status: :paid
    )
  end

  def calculate_delivery_stats
    today = Date.current
    {
      total_deliveries: DeliveryRequest.count,
      pending_deliveries: DeliveryRequest.where(status: 'pending').count,
      active_deliveries: DeliveryRequest.where(status: ['assigned', 'picked_up', 'in_transit']).count,
      completed_today: DeliveryRequest.where(status: 'delivered', delivered_at: today.beginning_of_day..today.end_of_day).count,
      cancelled_today: DeliveryRequest.where(status: 'cancelled', cancelled_at: today.beginning_of_day..today.end_of_day).count,
      total_revenue_today: DeliveryRequest.where(status: 'delivered', delivered_at: today.beginning_of_day..today.end_of_day).sum(:delivery_fee),
      average_delivery_fee: DeliveryRequest.where(status: 'delivered').average(:delivery_fee)&.round(2) || 0
    }
  end

  def build_delivery_timeline(delivery)
    timeline = []
    
    timeline << {
      time: delivery.requested_at,
      event: 'Delivery Requested',
      description: "Order #{delivery.marketplace_order.order_number} requested for delivery",
      status: 'info'
    }
    
    if delivery.assigned_at
      timeline << {
        time: delivery.assigned_at,
        event: 'Assigned to Driver',
        description: "Assigned to #{delivery.driver.full_name}",
        status: 'primary'
      }
    end
    
    if delivery.picked_up_at
      timeline << {
        time: delivery.picked_up_at,
        event: 'Order Picked Up',
        description: 'Driver picked up the order from pickup location',
        status: 'warning'
      }
    end
    
    if delivery.delivered_at
      timeline << {
        time: delivery.delivered_at,
        event: 'Order Delivered',
        description: 'Order successfully delivered to customer',
        status: 'success'
      }
    elsif delivery.cancelled_at
      timeline << {
        time: delivery.cancelled_at,
        event: 'Delivery Cancelled',
        description: delivery.cancellation_reason || 'Delivery was cancelled',
        status: 'danger'
      }
    end
    
    timeline.sort_by { |event| event[:time] }
  end

  def find_available_drivers_for_delivery(delivery)
    delivery.fleet_provider
           .available_drivers_for_delivery(
             delivery.pickup_latitude,
             delivery.pickup_longitude,
             delivery.fleet_provider.delivery_radius_km
           )
           .limit(10)
  end

  def calculate_average_delivery_time(start_date, end_date)
    completed_deliveries = DeliveryRequest.where(
      status: 'delivered',
      delivered_at: start_date..end_date
    ).where.not(assigned_at: nil)

    return 0 if completed_deliveries.empty?

    total_minutes = completed_deliveries.sum do |delivery|
      ((delivery.delivered_at - delivery.assigned_at) / 1.minute).round
    end

    (total_minutes / completed_deliveries.count).round
  end

  def top_performing_drivers(start_date, end_date)
    Driver.joins(:delivery_requests)
          .where(delivery_requests: { status: 'delivered', delivered_at: start_date..end_date })
          .group('drivers.id')
          .order('COUNT(delivery_requests.id) DESC')
          .limit(5)
          .select('drivers.*, COUNT(delivery_requests.id) as delivery_count')
  end

  def deliveries_by_day(start_date, end_date)
    # Use SQLite date function to group by day
    DeliveryRequest.where(created_at: start_date..end_date)
                  .group("date(created_at)")
                  .count
  end

  def deliveries_by_status(start_date, end_date)
    DeliveryRequest.where(created_at: start_date..end_date)
                  .group(:status)
                  .count
  end
end