class Marketplace::Order < ApplicationRecord
  belongs_to :user
  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items
  has_many :payments, dependent: :destroy
  has_one :delivery_request, dependent: :destroy

  enum :status, {
    pending: 0,
    processing: 1,
    shipped: 2,
    delivered: 3,
    cancelled: 4,
    refunded: 5
  }

  enum :payment_status, {
    unpaid: 0,
    paid: 1,
    partially_paid: 2,
    payment_refunded: 3
  }

  validates :order_number, presence: true, uniqueness: true
  validates :total_amount, presence: true, numericality: { greater_than: 0 }
  validates :status, :payment_status, presence: true

  before_validation :generate_order_number, on: :create

  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_payment_status, ->(payment_status) { where(payment_status: payment_status) }

  def total_items
    order_items.sum(:quantity)
  end

  def can_cancel?
    pending? || processing?
  end

  def can_refund?
    paid? && (delivered? || cancelled?)
  end

  def provider_orders
    # Group order items by service provider
    order_items.includes(:product).group_by { |item| item.product.user }
  end

  def requires_delivery?
    # You can customize this logic based on your business needs
    true  # For now, assume all orders require delivery
  end

  def create_delivery_request!(pickup_address:, pickup_lat:, pickup_lng:, delivery_address:, delivery_lat:, delivery_lng:, fleet_provider:, delivery_fee: nil)
    return delivery_request if delivery_request.present?
    
    # Calculate delivery fee if not provided
    calculated_fee = delivery_fee || calculate_delivery_fee(pickup_lat, pickup_lng, delivery_lat, delivery_lng)
    
    self.delivery_request = DeliveryRequest.create!(
      marketplace_order: self,
      customer: user,
      fleet_provider: fleet_provider,
      pickup_address: pickup_address,
      pickup_latitude: pickup_lat,
      pickup_longitude: pickup_lng,
      delivery_address: delivery_address,
      delivery_latitude: delivery_lat,
      delivery_longitude: delivery_lng,
      delivery_fee: calculated_fee,
      pickup_contact_name: user.name,
      pickup_contact_phone: user.phone || user.email,
      delivery_contact_name: user.name,
      delivery_contact_phone: user.phone || user.email
    )
    
    delivery_request
  end

  def delivery_status
    delivery_request&.status || 'no_delivery'
  end

  def estimated_delivery_time
    delivery_request&.estimated_delivery_time
  end

  def delivery_progress
    delivery_request&.delivery_progress || 0
  end

  private

  def calculate_delivery_fee(pickup_lat, pickup_lng, delivery_lat, delivery_lng)
    # Basic distance-based pricing
    distance_km = calculate_distance(pickup_lat, pickup_lng, delivery_lat, delivery_lng)
    base_fee = 5.0  # Base fee
    per_km_rate = 2.0  # Rate per kilometer
    
    (base_fee + (distance_km * per_km_rate)).round(2)
  end

  def calculate_distance(lat1, lng1, lat2, lng2)
    # Haversine formula
    rad_per_deg = Math::PI / 180
    rkm = 6371
    
    dlat_rad = (lat2 - lat1) * rad_per_deg
    dlon_rad = (lng2 - lng1) * rad_per_deg
    
    lat1_rad = lat1 * rad_per_deg
    lat2_rad = lat2 * rad_per_deg
    
    a = Math.sin(dlat_rad/2)**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(dlon_rad/2)**2
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
    
    rkm * c
  end

  def generate_order_number
    return if order_number.present?
    
    loop do
      self.order_number = "ORD-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(4).upcase}"
      break unless self.class.exists?(order_number: order_number)
    end
  end
end
