class Admin::CustomersController < AdminController
  before_action :set_customer, only: [:show, :edit, :update, :destroy, :activate, :suspend, :deactivate, :delivery_history]
  before_action :ensure_fleet_access
  
  def index
    @customers = scoped_customers.includes(:fleet_provider, :account_manager)
    
    # Filter by status if specified
    if params[:status].present?
      @customers = @customers.where(status: params[:status])
    end
    
    # Filter by business type if specified
    if params[:business_type].present?
      @customers = @customers.where(business_type: params[:business_type])
    end
    
    # System admin can filter by fleet provider, fleet admin sees only their customers
    if params[:fleet_provider_id].present? && system_admin?
      @customers = @customers.where(fleet_provider_id: params[:fleet_provider_id])
    end
    
    # Filter by date range
    if params[:date_from].present? && params[:date_to].present?
      @customers = @customers.where(created_at: params[:date_from]..params[:date_to])
    end
    
    # Search by name, contact, or email
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @customers = @customers.where(
        "business_name ILIKE ? OR primary_contact_name ILIKE ? OR primary_contact_email ILIKE ?",
        search_term, search_term, search_term
      )
    end
    
    # Sort options
    sort_by = params[:sort_by] || 'created_at'
    sort_direction = params[:sort_direction] || 'desc'
    @customers = @customers.order("#{sort_by} #{sort_direction}")
    
    # Pagination
    @customers = @customers.page(params[:page])
    
    # Data for filters (scoped to current user access)
    @fleet_providers = system_admin? ? FleetProvider.all : [current_fleet_provider].compact
    @business_types = Customer::BUSINESS_TYPES
    @stats = calculate_customer_stats
  end
  
  def show
    @delivery_requests = @customer.delivery_requests.recent.limit(20).includes(:driver)
    @pricing_rules = @customer.customer_pricing_rules.active.order(:priority) if @customer.respond_to?(:customer_pricing_rules)
    @invoices = @customer.invoices.order(created_at: :desc).limit(10) if @customer.respond_to?(:invoices)
    @analytics = calculate_customer_analytics(@customer)
  end
  
  def new
    @customer = scoped_customers.build
    load_form_data
  end
  
  def create
    @customer = scoped_customers.build(customer_params)
    
    # Fleet admin can only create customers for their fleet
    if fleet_admin? && current_fleet_provider
      @customer.fleet_provider = current_fleet_provider
    end
    
    # Set initial status based on activation preference
    if params[:activate_immediately] == '1'
      @customer.status = :active
      @customer.activated_at = Time.current
      @customer.status_notes = "Activated immediately upon creation by #{current_user.full_name}"
    else
      @customer.status = :pending_approval
      @customer.status_notes = "Created by #{current_user.full_name}, pending approval"
    end
    
    if @customer.save
      # Send welcome email if active
      # CustomerMailer.welcome_email(@customer).deliver_later if @customer.active?
      
      status_message = @customer.active? ? 'activated' : 'created and pending approval'
      flash[:notice] = "Customer '#{@customer.business_name}' was successfully #{status_message}."
      redirect_to admin_customer_path(@customer)
    else
      load_form_data
      render :new
    end
  end
  
  def edit
    load_form_data
  end
  
  def update
    if @customer.update(customer_params)
      flash[:notice] = "Customer '#{@customer.business_name}' was successfully updated."
      redirect_to admin_customer_path(@customer)
    else
      load_form_data
      render :edit
    end
  end
  
  def destroy
    customer_name = @customer.business_name
    
    if @customer.delivery_requests.any?
      flash[:alert] = "Cannot delete customer '#{customer_name}' because they have delivery requests."
      redirect_to admin_customer_path(@customer)
    else
      @customer.destroy
      flash[:notice] = "Customer '#{customer_name}' was successfully deleted."
      redirect_to admin_customers_path
    end
  end
  
  def activate
    @customer.activate!
    
    # Send activation email
    # CustomerMailer.activation_email(@customer).deliver_later
    
    flash[:notice] = "Customer '#{@customer.business_name}' has been activated."
    redirect_to admin_customer_path(@customer)
  end
  
  def suspend
    reason = params[:reason] || "Suspended by administrator"
    @customer.suspend!(reason)
    
    # Send suspension notification
    # CustomerMailer.suspension_email(@customer, reason).deliver_later
    
    flash[:notice] = "Customer '#{@customer.business_name}' has been suspended."
    redirect_to admin_customer_path(@customer)
  end
  
  def deactivate
    @customer.update!(status: :inactive, status_notes: "Deactivated by administrator")
    flash[:notice] = "Customer '#{@customer.business_name}' has been deactivated."
    redirect_to admin_customer_path(@customer)
  end
  
  def delivery_history
    @delivery_requests = @customer.delivery_requests.includes(:driver, :fleet_provider)
                                 .order(created_at: :desc)
                                 .page(params[:page])
                                 
    @stats = {
      total_deliveries: @customer.delivery_requests.count,
      completed_deliveries: @customer.delivery_requests.delivered.count,
      cancelled_deliveries: @customer.delivery_requests.cancelled.count,
      total_revenue: @customer.delivery_requests.delivered.sum(:delivery_fee),
      average_delivery_time: calculate_average_delivery_time(@customer),
      success_rate: calculate_success_rate(@customer)
    }
  end
  
  def bulk_actions
    customer_ids = params[:customer_ids] || []
    action = params[:bulk_action]
    
    return redirect_to(admin_customers_path, alert: "No customers selected") if customer_ids.empty?
    
    # Ensure user can only perform bulk actions on customers they have access to
    accessible_customers = scoped_customers.where(id: customer_ids)
    
    case action
    when 'activate'
      activated_count = bulk_activate(accessible_customers)
      flash[:notice] = "#{activated_count} customers activated"
      
    when 'suspend'
      reason = params[:suspension_reason] || 'Bulk suspended by administrator'
      suspended_count = bulk_suspend(accessible_customers, reason)
      flash[:notice] = "#{suspended_count} customers suspended"
      
    when 'change_fleet'
      if system_admin?
        fleet_provider = FleetProvider.find(params[:new_fleet_provider_id])
        updated_count = bulk_change_fleet(accessible_customers, fleet_provider)
        flash[:notice] = "#{updated_count} customers moved to #{fleet_provider.name}"
      else
        flash[:alert] = "You don't have permission to change fleet providers"
      end
      
    when 'assign_manager'
      account_manager = available_account_managers.find(params[:new_account_manager_id])
      updated_count = bulk_assign_manager(accessible_customers, account_manager)
      flash[:notice] = "#{updated_count} customers assigned to #{account_manager.full_name}"
      
    when 'export'
      redirect_to admin_customers_path(format: :csv, customer_ids: accessible_customers.pluck(:id))
      return
    else
      flash[:alert] = "Invalid bulk action"
    end
    
    redirect_to admin_customers_path
  end
  
  def analytics
    @date_range = params[:date_range] || '30'
    start_date = @date_range.to_i.days.ago.beginning_of_day
    end_date = Time.current.end_of_day
    
    customers_scope = scoped_customers
    
    @analytics_data = {
      # Overall stats
      total_customers: customers_scope.count,
      active_customers: customers_scope.active.count,
      pending_approval: customers_scope.pending_approval.count,
      suspended_customers: customers_scope.suspended.count,
      
      # Growth metrics
      new_customers_this_period: customers_scope.where(created_at: start_date..end_date).count,
      growth_rate: calculate_growth_rate(start_date, customers_scope),
      
      # Business metrics
      high_volume_customers: customers_scope.high_volume.count,
      top_rated_customers: customers_scope.top_rated.count,
      avg_deliveries_per_customer: customers_scope.active.average(:total_deliveries_count)&.round(1) || 0,
      total_customer_revenue: customers_scope.active.sum(:total_revenue),
      
      # Segmentation
      customers_by_type: customers_scope.group(:business_type).count,
      customers_by_status: customers_scope.group(:status).count,
      
      # Performance metrics
      avg_customer_rating: customers_scope.where.not(customer_rating: nil).average(:customer_rating)&.round(2) || 0,
      revenue_by_month: monthly_revenue_data(start_date, end_date, customers_scope),
      new_customers_by_month: monthly_signup_data(start_date, end_date, customers_scope)
    }
    
    # Add fleet breakdown only for system admin
    if system_admin?
      @analytics_data[:customers_by_fleet] = customers_scope.joins(:fleet_provider).group('fleet_providers.name').count
    end
  end
  
  def export
    @customers = scoped_customers.includes(:fleet_provider, :account_manager)
    
    # Apply same filters as index
    @customers = filter_customers(@customers)
    
    respond_to do |format|
      format.csv { send_csv_export(@customers) }
    end
  end
  
  private
  
  def set_customer
    @customer = scoped_customers.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Customer not found or you don't have access to it."
    redirect_to admin_customers_path
  end
  
  def scoped_customers
    if system_admin?
      Customer.all
    elsif current_fleet_provider
      current_fleet_provider.customers
    else
      Customer.none
    end
  end
  
  def customer_params
    permitted_params = [
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
      :account_manager_id, :special_terms,
      operating_hours: {}
    ]
    
    # Only system admin can change fleet provider
    permitted_params << :fleet_provider_id if system_admin?
    
    params.require(:customer).permit(permitted_params)
  end
  
  def load_form_data
    @fleet_providers = system_admin? ? FleetProvider.all : [current_fleet_provider].compact
    @account_managers = available_account_managers
    @business_types = Customer::BUSINESS_TYPES
    @payment_terms = Customer::PAYMENT_TERMS
  end
  
  def available_account_managers
    if system_admin?
      User.where(role: [:admin, :manager]).order(:first_name, :last_name)
    elsif current_fleet_provider
      # Fleet admin can assign users from their fleet or system managers
      current_fleet_provider.users.where(role: [:fleet_provider_admin, :fleet_provider_manager]) +
        User.where(role: [:admin, :manager])
    else
      User.none
    end
  end
  
  def calculate_customer_stats
    customers_scope = scoped_customers
    
    {
      total_customers: customers_scope.count,
      active_customers: customers_scope.active.count,
      pending_approval: customers_scope.pending_approval.count,
      suspended_customers: customers_scope.suspended.count,
      recent_signups: customers_scope.where('created_at > ?', 30.days.ago).count,
      high_volume_customers: customers_scope.high_volume.count,
      average_rating: customers_scope.where.not(customer_rating: nil).average(:customer_rating)&.round(2) || 0,
      total_revenue: customers_scope.sum(:total_revenue),
      avg_order_value: customers_scope.where('total_deliveries_count > 0').average(:average_order_value)&.round(2) || 0
    }
  end
  
  def calculate_customer_analytics(customer)
    deliveries = customer.delivery_requests
    completed_deliveries = deliveries.delivered
    
    {
      total_deliveries: deliveries.count,
      completed_deliveries: completed_deliveries.count,
      pending_deliveries: deliveries.where(status: [:pending, :assigned, :picked_up, :in_transit]).count,
      cancelled_deliveries: deliveries.cancelled.count,
      success_rate: deliveries.count > 0 ? (completed_deliveries.count.to_f / deliveries.count * 100).round(1) : 0,
      total_revenue: completed_deliveries.sum(:delivery_fee),
      average_delivery_fee: completed_deliveries.average(:delivery_fee)&.round(2) || 0,
      avg_delivery_time: calculate_average_delivery_time(customer),
      last_delivery: deliveries.order(:created_at).last&.created_at,
      monthly_deliveries: deliveries.where('created_at > ?', 30.days.ago).count,
      monthly_revenue: completed_deliveries.where('delivered_at > ?', 30.days.ago).sum(:delivery_fee)
    }
  end
  
  def calculate_average_delivery_time(customer)
    completed = customer.delivery_requests.delivered.where.not(delivered_at: nil, assigned_at: nil)
    return 0 if completed.empty?
    
    times = completed.map { |dr| dr.delivered_at - dr.assigned_at }
    (times.sum / times.size / 60).round # Convert to minutes
  end
  
  def calculate_success_rate(customer)
    total = customer.delivery_requests.count
    return 0 if total == 0
    
    completed = customer.delivery_requests.delivered.count
    (completed.to_f / total * 100).round(1)
  end
  
  def bulk_activate(customers)
    count = 0
    customers.each do |customer|
      if customer.pending_approval?
        customer.activate!
        # CustomerMailer.activation_email(customer).deliver_later
        count += 1
      end
    end
    count
  end
  
  def bulk_suspend(customers, reason)
    count = 0
    customers.each do |customer|
      if customer.active?
        customer.suspend!(reason)
        # CustomerMailer.suspension_email(customer, reason).deliver_later
        count += 1
      end
    end
    count
  end
  
  def bulk_change_fleet(customers, fleet_provider)
    return 0 unless system_admin?
    
    count = 0
    customers.each do |customer|
      if customer.update(fleet_provider: fleet_provider)
        count += 1
      end
    end
    count
  end
  
  def bulk_assign_manager(customers, account_manager)
    count = 0
    customers.each do |customer|
      if customer.update(account_manager: account_manager)
        count += 1
      end
    end
    count
  end
  
  def calculate_growth_rate(start_date, scope)
    previous_period_start = start_date - (Time.current - start_date)
    current_customers = scope.where(created_at: start_date..Time.current).count
    previous_customers = scope.where(created_at: previous_period_start..start_date).count
    
    return 0 if previous_customers == 0
    ((current_customers - previous_customers).to_f / previous_customers * 100).round(1)
  end
  
  def monthly_revenue_data(start_date, end_date, scope)
    scope.joins(:delivery_requests)
         .where(delivery_requests: { delivered_at: start_date..end_date })
         .group("DATE_TRUNC('month', delivery_requests.delivered_at)")
         .sum('delivery_requests.delivery_fee')
  end
  
  def monthly_signup_data(start_date, end_date, scope)
    scope.where(created_at: start_date..end_date)
         .group("DATE_TRUNC('month', created_at)")
         .count
  end
  
  def filter_customers(customers)
    # Apply same filters as index action
    customers = customers.where(status: params[:status]) if params[:status].present?
    customers = customers.where(business_type: params[:business_type]) if params[:business_type].present?
    customers = customers.where(fleet_provider_id: params[:fleet_provider_id]) if params[:fleet_provider_id].present? && system_admin?
    customers = customers.where(id: params[:customer_ids]) if params[:customer_ids].present?
    
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      customers = customers.where(
        "business_name ILIKE ? OR primary_contact_name ILIKE ? OR primary_contact_email ILIKE ?",
        search_term, search_term, search_term
      )
    end
    
    customers
  end
  
  def send_csv_export(customers)
    require 'csv'
    
    csv_data = CSV.generate(headers: true) do |csv|
      csv << [
        'ID', 'Business Name', 'Business Type', 'Contact Name', 'Contact Email', 'Contact Phone',
        'Status', 'Fleet Provider', 'Total Deliveries', 'Total Revenue', 'Rating', 'Created At'
      ]
      
      customers.each do |customer|
        csv << [
          customer.id,
          customer.business_name,
          customer.business_type,
          customer.primary_contact_name,
          customer.primary_contact_email,
          customer.primary_contact_phone,
          customer.status,
          customer.fleet_provider&.name,
          customer.total_deliveries_count,
          customer.total_revenue,
          customer.customer_rating,
          customer.created_at.strftime('%Y-%m-%d %H:%M')
        ]
      end
    end
    
    send_data csv_data, filename: "customers_export_#{Date.current}.csv", type: 'text/csv'
  end
end