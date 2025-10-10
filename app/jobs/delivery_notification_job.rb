class DeliveryNotificationJob < ApplicationJob
  queue_as :default

  def perform(notification_id)
    notification = DeliveryNotification.find(notification_id)
    notification.send_push_notification!
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "DeliveryNotificationJob: Notification not found: #{e.message}"
  rescue => e
    Rails.logger.error "DeliveryNotificationJob failed: #{e.message}"
    raise e
  end
end