class DashboardController < ApplicationController
  def index
    @dashboard_data = build_dashboard_data
  end

  private

  def build_dashboard_data
    case 
    when current_user.admin?
      admin_dashboard_data
    when current_user.fleet_provider_admin? || current_user.fleet_provider_manager? || current_user.fleet_provider_owner?
      fleet_provider_dashboard_data
    when current_user.service_provider?
      service_provider_dashboard_data
    else
      default_dashboard_data
    end
  end

  def admin_dashboard_data
    {
      # Fleet Management Stats
      total_fleet_providers: FleetProvider.count,
      active_fleet_providers: FleetProvider.where(license_status: 'active').count,
      total_vehicles: Vehicle.count,
      active_vehicles: Vehicle.where(status: 'active').count,
      total_drivers: Driver.count,
      total_trips: Trip.count,
      active_trips: Trip.where(status: 'in_progress').count,
      completed_trips_today: Trip.where(status: 'completed', updated_at: Date.current.beginning_of_day..Date.current.end_of_day).count,
      
      # Maintenance Stats
      total_maintenances: Maintenance.count,
      pending_maintenances: Maintenance.joins(:vehicle).where(status: 'pending').count,
      maintenance_cost_this_month: Maintenance.where(maintenance_date: Date.current.beginning_of_month..Date.current.end_of_month).sum(:maintenance_cost),
      
      # Marketplace Stats
      total_marketplace_products: Marketplace::Product.count,
      active_marketplace_products: Marketplace::Product.active.count,
      featured_products: Marketplace::Product.featured.count,
      marketplace_revenue_this_month: calculate_marketplace_revenue(Date.current.beginning_of_month, Date.current.end_of_month),
      
      # Recent Activity
      recent_fleet_providers: FleetProvider.order(created_at: :desc).limit(5),
      recent_vehicles: Vehicle.includes(:fleet_provider, :vehicle_model).order(created_at: :desc).limit(5),
      recent_trips: Trip.includes(:vehicle, :driver, :fleet_provider).order(created_at: :desc).limit(5),
      recent_marketplace_products: Marketplace::Product.includes(:user).order(created_at: :desc).limit(5),
      
      # Charts Data
      monthly_trips: monthly_trips_data,
      vehicle_status_breakdown: vehicle_status_breakdown,
      maintenance_type_breakdown: maintenance_type_breakdown,
      marketplace_category_breakdown: marketplace_category_breakdown
    }
  end

  def fleet_provider_dashboard_data
    user_fleet_providers = current_user.fleet_providers
    
    {
      # My Fleet Stats
      my_fleet_providers: user_fleet_providers.count,
      total_vehicles: Vehicle.where(fleet_provider: user_fleet_providers).count,
      active_vehicles: Vehicle.where(fleet_provider: user_fleet_providers, status: 'active').count,
      total_drivers: Driver.where(fleet_provider: user_fleet_providers).count,
      total_trips: Trip.where(fleet_provider: user_fleet_providers).count,
      active_trips: Trip.where(fleet_provider: user_fleet_providers, status: 'in_progress').count,
      completed_trips_today: Trip.where(fleet_provider: user_fleet_providers, status: 'completed', updated_at: Date.current.beginning_of_day..Date.current.end_of_day).count,
      
      # My Maintenance Stats
      total_maintenances: Maintenance.joins(:vehicle).where(vehicles: { fleet_provider: user_fleet_providers }).count,
      pending_maintenances: Maintenance.joins(:vehicle).where(vehicles: { fleet_provider: user_fleet_providers }, status: 'pending').count,
      maintenance_cost_this_month: Maintenance.joins(:vehicle).where(vehicles: { fleet_provider: user_fleet_providers }, maintenance_date: Date.current.beginning_of_month..Date.current.end_of_month).sum(:maintenance_cost),
      
      # Recent Activity
      recent_vehicles: Vehicle.where(fleet_provider: user_fleet_providers).includes(:vehicle_model).order(created_at: :desc).limit(5),
      recent_trips: Trip.where(fleet_provider: user_fleet_providers).includes(:vehicle, :driver).order(created_at: :desc).limit(5),
      recent_maintenances: Maintenance.joins(:vehicle).where(vehicles: { fleet_provider: user_fleet_providers }).includes(:vehicle).order(created_at: :desc).limit(5),
      
      # Charts Data
      monthly_trips: monthly_trips_data(user_fleet_providers),
      vehicle_status_breakdown: vehicle_status_breakdown(user_fleet_providers),
      maintenance_type_breakdown: maintenance_type_breakdown(user_fleet_providers)
    }
  end

  def service_provider_dashboard_data
    {
      # My Marketplace Stats
      my_products: Marketplace::Product.where(user: current_user).count,
      active_products: Marketplace::Product.where(user: current_user).active.count,
      featured_products: Marketplace::Product.where(user: current_user).featured.count,
      total_views: 0, # TODO: Implement view tracking
      
      # Revenue Stats (if applicable)
      revenue_this_month: calculate_user_marketplace_revenue(current_user, Date.current.beginning_of_month, Date.current.end_of_month),
      revenue_last_month: calculate_user_marketplace_revenue(current_user, Date.current.last_month.beginning_of_month, Date.current.last_month.end_of_month),
      
      # Recent Activity
      recent_products: Marketplace::Product.where(user: current_user).order(created_at: :desc).limit(5),
      
      # Charts Data
      product_category_breakdown: product_category_breakdown(current_user),
      monthly_product_creation: monthly_product_creation_data(current_user)
    }
  end

  def default_dashboard_data
    {
      # Basic stats for regular users
      total_marketplace_products: Marketplace::Product.active.count,
      featured_products: Marketplace::Product.featured.count,
      recent_products: Marketplace::Product.active.includes(:user).order(created_at: :desc).limit(10)
    }
  end

  # Helper methods for data calculations
  def calculate_marketplace_revenue(start_date, end_date)
    # TODO: Implement actual revenue calculation when order/sales system is in place
    0
  end

  def calculate_user_marketplace_revenue(user, start_date, end_date)
    # TODO: Implement actual revenue calculation when order/sales system is in place
    0
  end

  def monthly_trips_data(fleet_providers = nil)
    base_query = fleet_providers ? Trip.where(fleet_provider: fleet_providers) : Trip
    
    (0..11).map do |i|
      month = i.months.ago.beginning_of_month
      [
        month.strftime('%b'),
        base_query.where(created_at: month..month.end_of_month).count
      ]
    end.reverse
  end

  def vehicle_status_breakdown(fleet_providers = nil)
    base_query = fleet_providers ? Vehicle.where(fleet_provider: fleet_providers) : Vehicle
    
    {
      'Active' => base_query.where(status: 'active').count,
      'Inactive' => base_query.where(status: 'inactive').count,
      'Maintenance' => base_query.where(status: 'maintenance').count
    }
  end

  def maintenance_type_breakdown(fleet_providers = nil)
    base_query = fleet_providers ? Maintenance.joins(:vehicle).where(vehicles: { fleet_provider: fleet_providers }) : Maintenance
    
    {
      'Service' => base_query.where(maintenance_type: 'service').count,
      'Repair' => base_query.where(maintenance_type: 'repair').count,
      'Inspection' => base_query.where(maintenance_type: 'inspection').count
    }
  end

  def marketplace_category_breakdown
    categories = Marketplace::Product.active.group(:category).count
    categories.transform_keys(&:titleize)
  end

  def product_category_breakdown(user)
    categories = Marketplace::Product.where(user: user).group(:category).count
    categories.transform_keys(&:titleize)
  end

  def monthly_product_creation_data(user)
    (0..11).map do |i|
      month = i.months.ago.beginning_of_month
      [
        month.strftime('%b'),
        Marketplace::Product.where(user: user, created_at: month..month.end_of_month).count
      ]
    end.reverse
  end
end
