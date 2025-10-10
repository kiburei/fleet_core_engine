class Admin::DashboardController < AdminController
  
  def index
    @recent_deliveries = DeliveryRequest.includes(:driver, :customer, :fleet_provider)
                                       .recent
                                       .limit(10)
    
    @active_drivers = Driver.joins(:user)
                           .where(status: ['online', 'busy'])
                           .includes(:fleet_provider, :current_delivery_request)
                           .limit(10)
    
    @fleet_providers = FleetProvider.includes(:drivers)
    
    @stats = {
      pending_deliveries: pending_deliveries_count,
      available_drivers: available_drivers_count,
      today_deliveries: today_deliveries_count,
      completion_rate: completion_rate
    }
  end
  
  private
  
  def pending_deliveries_count
    DeliveryRequest.pending.count
  end
  
  def available_drivers_count
    Driver.available.count
  end
  
  def today_deliveries_count
    DeliveryRequest.where(created_at: Date.current.all_day).count
  end
  
  def completion_rate(period = 30.days)
    scope = DeliveryRequest.where(created_at: period.ago..Time.current)
    total = scope.count
    return 0 if total.zero?
    
    completed = scope.delivered.count
    ((completed.to_f / total) * 100).round(1)
  end
end