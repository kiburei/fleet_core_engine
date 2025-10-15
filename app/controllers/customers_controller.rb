class CustomersController < ApplicationController
  before_action :set_customer, only: [:show, :edit, :update, :destroy, :activate, :suspend]
  
  def index
    @customers = Customer.includes(:fleet_provider, :account_manager)
    
    # Filter by status if specified
    if params[:status].present?
      @customers = @customers.where(status: params[:status])
    end
    
    # Filter by business type if specified
    if params[:business_type].present?
      @customers = @customers.where(business_type: params[:business_type])
    end
    
    # Filter by fleet provider if specified
    if params[:fleet_provider_id].present?
      @customers = @customers.where(fleet_provider_id: params[:fleet_provider_id])
    end
    
    # Search by name or contact
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @customers = @customers.where(
        "business_name ILIKE ? OR primary_contact_name ILIKE ? OR primary_contact_email ILIKE ?",
        search_term, search_term, search_term
      )
    end
    
    # Order by creation date (newest first)
    @customers = @customers.order(created_at: :desc).page(params[:page])
    
    @fleet_providers = FleetProvider.all
    @business_types = Customer::BUSINESS_TYPES
    @stats = calculate_customer_stats
  end
  
  def show
    @delivery_requests = @customer.delivery_requests.recent.limit(10).includes(:driver)
    @pricing_rules = @customer.customer_pricing_rules.active.by_priority
    @analytics = @customer.usage_stats if @customer.active?
  end
  
  def new
    @customer = Customer.new
    @fleet_providers = FleetProvider.all
    @account_managers = User.all.order(:first_name, :last_name)
    @business_types = Customer::BUSINESS_TYPES
    @payment_terms = Customer::PAYMENT_TERMS
  end
  
  def create
    @customer = Customer.new(customer_params)
    
    if @customer.save
      flash[:notice] = "Customer '#{@customer.business_name}' was successfully created and is pending approval."
      redirect_to customer_path(@customer)
    else
      @fleet_providers = FleetProvider.all
      @account_managers = User.all.order(:first_name, :last_name)
      @business_types = Customer::BUSINESS_TYPES
      @payment_terms = Customer::PAYMENT_TERMS
      render :new
    end
  end
  
  def edit
    @fleet_providers = FleetProvider.all
    @account_managers = User.all.order(:first_name, :last_name)
    @business_types = Customer::BUSINESS_TYPES
    @payment_terms = Customer::PAYMENT_TERMS
  end
  
  def update
    if @customer.update(customer_params)
      flash[:notice] = "Customer '#{@customer.business_name}' was successfully updated."
      redirect_to customer_path(@customer)
    else
      @fleet_providers = FleetProvider.all
      @account_managers = User.all.order(:first_name, :last_name)
      @business_types = Customer::BUSINESS_TYPES
      @payment_terms = Customer::PAYMENT_TERMS
      render :edit
    end
  end
  
  def destroy
    customer_name = @customer.business_name
    
    if @customer.delivery_requests.any?
      flash[:alert] = "Cannot delete customer '#{customer_name}' because they have delivery requests."
      redirect_to customer_path(@customer)
    else
      @customer.destroy
      flash[:notice] = "Customer '#{customer_name}' was successfully deleted."
      redirect_to customers_path
    end
  end
  
  def activate
    @customer.activate!
    flash[:notice] = "Customer '#{@customer.business_name}' has been activated."
    redirect_to customer_path(@customer)
  end
  
  def suspend
    reason = params[:reason] || "Suspended by administrator"
    @customer.suspend!(reason)
    flash[:notice] = "Customer '#{@customer.business_name}' has been suspended."
    redirect_to customer_path(@customer)
  end
  
  def bulk_actions
    customer_ids = params[:customer_ids] || []
    action = params[:bulk_action]
    
    case action
    when 'activate'
      activated_count = 0
      customer_ids.each do |id|
        customer = Customer.find(id)
        if customer.pending_approval?
          customer.activate!
          activated_count += 1
        end
      end
      flash[:notice] = "#{activated_count} customers activated"
      
    when 'suspend'
      reason = params[:suspension_reason] || 'Bulk suspended'
      suspended_count = 0
      customer_ids.each do |id|
        customer = Customer.find(id)
        if customer.active?
          customer.suspend!(reason)
          suspended_count += 1
        end
      end
      flash[:notice] = "#{suspended_count} customers suspended"
      
    when 'change_fleet'
      fleet_provider = FleetProvider.find(params[:new_fleet_provider_id])
      updated_count = 0
      customer_ids.each do |id|
        customer = Customer.find(id)
        if customer.update(fleet_provider: fleet_provider)
          updated_count += 1
        end
      end
      flash[:notice] = "#{updated_count} customers moved to #{fleet_provider.name}"
    end
    
    redirect_to customers_path
  end
  
  def analytics
    @date_range = params[:date_range] || '30'
    start_date = @date_range.to_i.days.ago.beginning_of_day
    end_date = Time.current.end_of_day
    
    @analytics_data = {
      total_customers: Customer.count,
      active_customers: Customer.active.count,
      pending_approval: Customer.pending_approval.count,
      suspended_customers: Customer.suspended.count,
      new_customers_this_period: Customer.where(created_at: start_date..end_date).count,
      high_volume_customers: Customer.high_volume.count,
      top_rated_customers: Customer.top_rated.count,
      customers_by_type: Customer.group(:business_type).count,
      customers_by_fleet: Customer.joins(:fleet_provider).group('fleet_providers.name').count,
      avg_deliveries_per_customer: Customer.active.average(:total_deliveries_count)&.round(1) || 0,
      total_customer_revenue: Customer.active.sum(:total_revenue)
    }
  end
  
  # Customer Onboarding Workflow
  def new_registration
    @customer = Customer.new
    @fleet_providers = FleetProvider.where(is_delivery_enabled: true)
    @business_types = Customer::BUSINESS_TYPES
    render 'registration/new'
  end
  
  def create_registration
    @customer = Customer.new(registration_params)
    @customer.status = :pending_approval
    
    if @customer.save
      # Send confirmation email to customer
      # CustomerMailer.registration_confirmation(@customer).deliver_later
      
      # Notify fleet provider admin
      # CustomerMailer.new_customer_notification(@customer.fleet_provider, @customer).deliver_later
      
      # Notify system admin
      # CustomerMailer.new_customer_system_notification(@customer).deliver_later
      
      flash[:success] = "Registration submitted successfully! You will receive an email confirmation shortly."
      redirect_to onboarding_complete_customers_path(customer_id: @customer.id)
    else
      @fleet_providers = FleetProvider.where(is_delivery_enabled: true)
      @business_types = Customer::BUSINESS_TYPES
      render 'registration/new'
    end
  end
  
  def onboarding_complete
    @customer = Customer.find(params[:customer_id]) if params[:customer_id]
    render 'registration/complete'
  end
  
  def onboarding_status
    # This would be used to check the status of onboarding via AJAX
    render json: {
      status: @customer.status,
      message: onboarding_status_message(@customer)
    }
  end
  
  private
  
  def set_customer
    @customer = Customer.find(params[:id])
  end
  
  def customer_params
    params.require(:customer).permit(
      :business_name, :business_type, :business_registration_number, :business_description,
      :primary_contact_name, :primary_contact_phone, :primary_contact_email,
      :secondary_contact_name, :secondary_contact_phone, :secondary_contact_email,
      :business_address, :city, :state, :country, :postal_code, :timezone,
      :payment_terms, :billing_contact_name, :billing_contact_email, :billing_contact_phone,
      :billing_address, :tax_id_number,
      :default_payment_method, :business_payment_percentage,
      :base_delivery_rate, :per_km_rate, :minimum_order_value, :free_delivery_threshold,
      :max_delivery_radius_km, :estimated_prep_time_minutes,
      :allows_cash_on_delivery, :allows_card_on_delivery, :requires_signature, :allows_contactless_delivery,
      :fleet_provider_id, :account_manager_id, :special_terms,
      operating_hours: {}
    )
  end
  
  def calculate_customer_stats
    {
      total_customers: Customer.count,
      active_customers: Customer.active.count,
      pending_approval: Customer.pending_approval.count,
      suspended_customers: Customer.suspended.count,
      recent_signups: Customer.where('created_at > ?', 30.days.ago).count,
      high_volume_customers: Customer.high_volume.count,
      average_rating: Customer.where.not(customer_rating: nil).average(:customer_rating)&.round(2) || 0
    }
  end
  
  def registration_params
    params.require(:customer).permit(
      :business_name, :business_type, :business_registration_number, :business_description,
      :primary_contact_name, :primary_contact_phone, :primary_contact_email,
      :secondary_contact_name, :secondary_contact_phone, :secondary_contact_email,
      :business_address, :city, :state, :country, :postal_code, :timezone,
      :payment_terms, :billing_contact_name, :billing_contact_email, :billing_contact_phone,
      :billing_address, :tax_id_number,
      :default_payment_method, :business_payment_percentage,
      :max_delivery_radius_km, :estimated_prep_time_minutes,
      :allows_cash_on_delivery, :allows_card_on_delivery, :requires_signature, :allows_contactless_delivery,
      :fleet_provider_id, :special_terms,
      operating_hours: {}
    )
  end
  
  def onboarding_status_message(customer)
    case customer.status
    when 'pending_approval'
      "Your registration is being reviewed. You'll receive an email once approved."
    when 'active'
      "Welcome! Your account is active and ready to use."
    when 'suspended'
      "Your account has been suspended. Please contact support."
    when 'inactive'
      "Your account is currently inactive."
    else
      "Registration status unknown."
    end
  end
end
