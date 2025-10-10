class DeliveryDispatchJob < ApplicationJob
  queue_as :default

  def perform(delivery_request_id)
    delivery_request = DeliveryRequest.find(delivery_request_id)
    return unless delivery_request.can_be_assigned?

    dispatch_service = DeliveryDispatchService.new(delivery_request)
    
    # Try automatic assignment first
    assigned = dispatch_service.find_and_assign_driver(notify_nearby: true)
    
    # If automatic assignment fails, broadcast to available drivers
    unless assigned
      drivers_notified = dispatch_service.broadcast_to_available_drivers
      Rails.logger.info "Broadcasted delivery #{delivery_request.request_number} to #{drivers_notified} drivers"
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "DeliveryDispatchJob: Delivery request not found: #{e.message}"
  rescue => e
    Rails.logger.error "DeliveryDispatchJob failed: #{e.message}"
    raise e
  end
end