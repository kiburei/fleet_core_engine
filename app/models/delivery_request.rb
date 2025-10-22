class DeliveryRequest < ApplicationRecord
  belongs_to :marketplace_order, class_name: 'Marketplace::Order'
  belongs_to :business_customer, class_name: 'Customer'
  belongs_to :driver, optional: true
  belongs_to :fleet_provider

  has_many :location_trackings, dependent: :destroy
  has_many :delivery_notifications, dependent: :destroy

  # Enums
  enum :status, {
    pending: 0,
    assigned: 1,
    picked_up: 2,
    in_transit: 3,
    delivered: 4,
    cancelled: 5,
    failed: 6
  }

  enum :priority, {
    normal: 0,
    high: 1,
    urgent: 2
  }

  enum :payment_status, {
    unpaid: 0,
    paid: 1,
    refunded: 2
  }

  # Validations
  validates :request_number, presence: true, uniqueness: true
  validates :pickup_address, :delivery_address, presence: true
  # Coordinates will be automatically geocoded from addresses if not provided
  validates :pickup_latitude, :pickup_longitude, :delivery_latitude, :delivery_longitude, presence: { message: "could not be determined from address. Please check the address or enter coordinates manually." }
  validates :delivery_fee, presence: true, numericality: { greater_than: 0 }
  validates :requested_at, presence: true
  validates :end_customer_name, presence: true
  validates :end_customer_phone, presence: true
  validates :order_value, numericality: { greater_than: 0 }, allow_nil: true
  validates :business_payment_amount, :customer_payment_amount, numericality: { greater_than_or_equal_to: 0 }

  # Geocoding
  geocoded_by :pickup_address, latitude: :pickup_latitude, longitude: :pickup_longitude
  reverse_geocoded_by :pickup_latitude, :pickup_longitude, address: :pickup_address
  
  geocoded_by :delivery_address, latitude: :delivery_latitude, longitude: :delivery_longitude
  reverse_geocoded_by :delivery_latitude, :delivery_longitude, address: :delivery_address

  # Callbacks
  before_validation :generate_request_number, on: :create
  before_validation :set_requested_at, on: :create
  before_validation :geocode_addresses, if: :should_geocode?
  before_validation :calculate_fees_if_needed, if: :should_calculate_fees?
  after_update :broadcast_status_update, if: :saved_change_to_status?
  after_update :notify_status_change, if: :saved_change_to_status?
  after_update :update_customer_analytics!, if: :saved_change_to_status? && :delivered?

  # Scopes
  scope :recent, -> { order(requested_at: :desc) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_priority, ->(priority) { where(priority: priority) }
  scope :for_driver, ->(driver) { where(driver: driver) }
  scope :unassigned, -> { where(driver: nil, status: :pending) }
  scope :assigned_today, -> { where(assigned_at: Date.current.beginning_of_day..Date.current.end_of_day) }

  def assign_to_driver!(driver)
    raise ArgumentError, "Driver cannot accept this delivery" unless driver.can_accept_delivery?(self)
    
    transaction do
      update!(
        driver: driver,
        status: :assigned,
        assigned_at: Time.current
      )
      
      # Calculate commission and platform fee
      calculate_fees!
      
      # Send notification to driver
      notify_driver_assignment
      
      # Update order status
      marketplace_order.update!(status: :processing) if marketplace_order.pending?
    end
  end

  def pickup!
    raise ArgumentError, "Cannot pickup unassigned delivery" unless assigned?
    
    update!(
      status: :picked_up,
      picked_up_at: Time.current
    )
  end

  def mark_in_transit!
    raise ArgumentError, "Cannot mark as in transit before pickup" unless picked_up?
    
    update!(status: :in_transit)
  end

  def deliver!
    raise ArgumentError, "Cannot deliver before pickup" unless picked_up? || in_transit?
    
    transaction do
      update!(
        status: :delivered,
        delivered_at: Time.current,
        payment_status: :paid
      )
      
      # Update marketplace order
      marketplace_order.update!(status: :delivered)
      
      # Update driver stats
      driver.increment!(:total_deliveries)
      
      # Process payment to driver
      process_driver_payment
    end
  end

  def cancel!(reason = nil)
    raise ArgumentError, "Cannot cancel delivered orders" if delivered?
    
    transaction do
      update!(
        status: :cancelled,
        cancelled_at: Time.current,
        cancellation_reason: reason
      )
      
      # Free up the driver
      update!(driver: nil) if driver.present?
      
      # Update marketplace order
      marketplace_order.update!(status: :cancelled) unless marketplace_order.delivered?
    end
  end

  def estimated_delivery_time
    return nil unless estimated_duration_minutes
    
    base_time = assigned_at || requested_at
    if picked_up?
      base_time = picked_up_at
    end
    
    base_time + estimated_duration_minutes.minutes
  end

  def distance_km
    return estimated_distance_km if estimated_distance_km.present?
    
    # Calculate distance using Haversine formula
    calculate_distance
  end

  def driver_location
    return nil unless driver&.current_location
    driver.current_location
  end

  def time_since_requested
    return 0 unless requested_at
    ((Time.current - requested_at) / 1.minute).round
  end

  def time_since_assigned
    return nil unless assigned_at
    ((Time.current - assigned_at) / 1.minute).round
  end

  def delivery_progress
    return 0 if pending?
    return 25 if assigned?
    return 50 if picked_up?
    return 75 if in_transit?
    return 100 if delivered?
    0
  end

  def can_be_assigned?
    pending? && driver.nil?
  end

  def can_be_cancelled?
    !delivered? && !cancelled?
  end

  def customer
    business_customer
  end

  private

  def generate_request_number
    return if request_number.present?
    
    loop do
      self.request_number = "DR-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(4).upcase}"
      break unless self.class.exists?(request_number: request_number)
    end
  end

  def set_requested_at
    self.requested_at ||= Time.current
  end

  def calculate_distance
    return 0 unless pickup_latitude && pickup_longitude && delivery_latitude && delivery_longitude
    
    # Haversine formula
    rad_per_deg = Math::PI / 180
    rkm = 6371
    
    dlat_rad = (delivery_latitude - pickup_latitude) * rad_per_deg
    dlon_rad = (delivery_longitude - pickup_longitude) * rad_per_deg
    
    lat1_rad = pickup_latitude * rad_per_deg
    lat2_rad = delivery_latitude * rad_per_deg
    
    a = Math.sin(dlat_rad/2)**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(dlon_rad/2)**2
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
    
    distance = rkm * c
    
    # Only update the database if the record has been saved
    if persisted?
      update_column(:estimated_distance_km, distance.round(2))
    else
      # For new records, just set the attribute
      self.estimated_distance_km = distance.round(2)
    end
    
    distance
  end

  def calculate_fees!
    base_fee = delivery_fee
    commission_rate = fleet_provider.delivery_commission_rate || 0.15 # 15% default
    platform_rate = 0.05 # 5% platform fee
    
    self.driver_commission = base_fee * (1 - commission_rate - platform_rate)
    self.platform_fee = base_fee * platform_rate
    save!
  end

  def broadcast_status_update
    # Broadcast to real-time channels
    ActionCable.server.broadcast(
      "delivery_request_#{id}",
      {
        status: status,
        progress: delivery_progress,
        driver_location: driver_location,
        estimated_delivery_time: estimated_delivery_time&.iso8601,
        updated_at: updated_at.iso8601
      }
    )
  end

  def notify_status_change
    case status
    when 'assigned'
      notify_customer('delivery_assigned', 'Delivery Assigned', "Your order has been assigned to #{driver.full_name}")
      notify_driver_assignment
    when 'picked_up'
      notify_customer('order_picked_up', 'Order Picked Up', 'Your order has been picked up and is on the way')
    when 'delivered'
      notify_customer('order_delivered', 'Order Delivered', 'Your order has been delivered successfully')
      notify_driver('delivery_completed', 'Delivery Completed', "You've successfully completed delivery #{request_number}")
    when 'cancelled'
      notify_customer('delivery_cancelled', 'Delivery Cancelled', "Your delivery has been cancelled. #{cancellation_reason}")
      notify_driver('delivery_cancelled', 'Delivery Cancelled', "Delivery #{request_number} has been cancelled") if driver
    end
  end

  def notify_customer(type, title, message)
    # Skip notification if customer is not a User (business_customer is a Customer model)
    # TODO: Implement customer notification system for Customer model
    return unless customer.is_a?(User)
    
    delivery_notifications.create!(
      recipient: customer,
      notification_type: type,
      title: title,
      message: message,
      metadata: { delivery_request_id: id }
    )
  rescue => e
    Rails.logger.error "Failed to send customer notification: #{e.message}"
  end

  def notify_driver(type, title, message)
    return unless driver
    
    delivery_notifications.create!(
      recipient: driver.user,
      notification_type: type,
      title: title,
      message: message,
      metadata: { delivery_request_id: id }
    )
  end

  def notify_driver_assignment
    return unless driver
    
    notify_driver(
      'order_assigned',
      'New Delivery Assignment',
      "You have been assigned delivery #{request_number}. Pickup: #{pickup_address}"
    )
  end

  def process_driver_payment
    # This would integrate with your payment system
    # For now, just mark as paid
    update_column(:payment_status, :paid)
  end

  def should_geocode?
    # Geocode if we have address but missing coordinates
    (pickup_address_changed? && (pickup_latitude.blank? || pickup_longitude.blank?)) ||
    (delivery_address_changed? && (delivery_latitude.blank? || delivery_longitude.blank?))
  end

  def should_calculate_fees?
    # Calculate fees if coordinates or order value changed and we have a business customer
    business_customer.present? && (
      pickup_latitude_changed? || pickup_longitude_changed? ||
      delivery_latitude_changed? || delivery_longitude_changed? ||
      order_value_changed?
    ) && pickup_latitude.present? && delivery_latitude.present?
  end

  def calculate_fees_if_needed
    calculate_delivery_fee_with_customer_rules!
  end

  def geocode_addresses
    geocode_pickup_address if pickup_address.present? && (pickup_latitude.blank? || pickup_longitude.blank?)
    geocode_delivery_address if delivery_address.present? && (delivery_latitude.blank? || delivery_longitude.blank?)
  end

  def geocode_pickup_address
    return unless pickup_address.present?
    
    begin
      result = GeocodingService.geocode(pickup_address)
      if result
        self.pickup_latitude = result[:latitude]
        self.pickup_longitude = result[:longitude]
        self.pickup_place_id = result[:place_id]
        # Update address to the formatted one from geocoding service
        self.pickup_address = result[:formatted_address] if result[:formatted_address].present?
      end
    rescue GeocodingService::GeocodingError => e
      Rails.logger.warn("Failed to geocode pickup address '#{pickup_address}': #{e.message}")
      errors.add(:pickup_address, "could not be found. Please check the address or enter coordinates manually.")
    end
  end

  def geocode_delivery_address
    return unless delivery_address.present?
    
    begin
      result = GeocodingService.geocode(delivery_address)
      if result
        self.delivery_latitude = result[:latitude]
        self.delivery_longitude = result[:longitude]
        self.delivery_place_id = result[:place_id]
        # Update address to the formatted one from geocoding service
        self.delivery_address = result[:formatted_address] if result[:formatted_address].present?
      end
    rescue GeocodingService::GeocodingError => e
      Rails.logger.warn("Failed to geocode delivery address '#{delivery_address}': #{e.message}")
      errors.add(:delivery_address, "could not be found. Please check the address or enter coordinates manually.")
    end
  end

  # Method to retry geocoding if needed
  def retry_geocoding!
    geocode_addresses
    save!
  end

  # Customer and payment methods
  def end_customer_info
    {
      name: end_customer_name,
      phone: end_customer_phone,
      email: end_customer_email
    }
  end

  def calculate_delivery_fee_with_customer_rules!
    return unless business_customer && pickup_latitude && delivery_latitude
    
    distance = distance_km || calculate_distance
    calculated_fee = business_customer.calculate_delivery_fee(distance, order_value || 0)
    
    self.delivery_fee = calculated_fee
    
    # Split the payment based on customer settings
    split_payment_amounts!
    
    calculated_fee
  end

  def split_payment_amounts!
    return unless business_customer && delivery_fee
    
    split = business_customer.split_delivery_fee(delivery_fee)
    self.business_payment_amount = split[:business_amount]
    self.customer_payment_amount = split[:customer_amount]
  end

  def payment_split_description
    return "Customer pays all (#{delivery_fee})" if business_payment_amount == 0
    return "Business pays all (#{delivery_fee})" if customer_payment_amount == 0
    return "Split: Business (#{business_payment_amount}) + Customer (#{customer_payment_amount})"
  end

  def within_customer_delivery_radius?
    return false unless business_customer && delivery_latitude && delivery_longitude
    
    business_customer.within_delivery_radius?(delivery_latitude, delivery_longitude)
  end

  def customer_can_place_orders?
    business_customer&.can_place_orders?
  end

  def update_customer_analytics!
    business_customer&.update_analytics!
  end
end
