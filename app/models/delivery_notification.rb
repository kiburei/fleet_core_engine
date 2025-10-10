class DeliveryNotification < ApplicationRecord
  belongs_to :delivery_request
  belongs_to :recipient, class_name: 'User'

  validates :notification_type, presence: true
  validates :title, :message, presence: true

  scope :unread, -> { where(read: false) }
  scope :read, -> { where(read: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(notification_type: type) }
  scope :for_user, ->(user) { where(recipient: user) }

  after_create :send_push_notification

  NOTIFICATION_TYPES = [
    'order_assigned',
    'order_picked_up',
    'order_delivered',
    'delivery_assigned',
    'delivery_cancelled',
    'delivery_completed',
    'payment_received'
  ].freeze

  validates :notification_type, inclusion: { in: NOTIFICATION_TYPES }

  def mark_as_read!
    update!(read: true)
  end

  def mark_as_unread!
    update!(read: false)
  end

  def send_push_notification!
    return if push_sent?
    
    # Send push notification if recipient has FCM token
    if recipient.is_a?(Driver) && recipient.fcm_token.present?
      send_fcm_notification
    elsif recipient.fcm_token.present?
      send_fcm_notification
    end

    update!(push_sent: true, sent_at: Time.current)
  end

  private

  def send_push_notification
    DeliveryNotificationJob.perform_later(id)
  end

  def send_fcm_notification
    return unless recipient.respond_to?(:fcm_token) && recipient.fcm_token.present?

    begin
      fcm = FCM.new(Rails.application.credentials.firebase_server_key)
      
      response = fcm.send(
        [recipient.fcm_token],
        {
          notification: {
            title: title,
            body: message
          },
          data: {
            notification_type: notification_type,
            delivery_request_id: delivery_request_id.to_s,
            created_at: created_at.iso8601
          }.merge(metadata || {})
        }
      )

      Rails.logger.info "FCM response: #{response}"
    rescue => e
      Rails.logger.error "Failed to send FCM notification: #{e.message}"
    end
  end
end