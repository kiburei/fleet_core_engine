class Customer < ApplicationRecord
  belongs_to :fleet_provider
  belongs_to :account_manager, class_name: 'User', optional: true
  
  has_many :delivery_requests, foreign_key: :business_customer_id, dependent: :restrict_with_exception
  has_many :customer_pricing_rules, dependent: :destroy
  has_many :invoices, dependent: :destroy
  
  # Enums
  enum :status, {
    pending_approval: 0,
    active: 1,
    inactive: 2,
    suspended: 3
  }
  
  enum :default_payment_method, {
    customer_pays: 0,      # End customer pays delivery fee
    business_pays: 1,      # Business pays delivery fee
    split_payment: 2       # Split between business and customer
  }
  
  # Validations
  validates :business_name, presence: true, length: { minimum: 2, maximum: 255 }
  validates :business_type, presence: true
  validates :primary_contact_name, presence: true
  validates :primary_contact_phone, presence: true, format: { with: /\A[+]?[\d\s\-\(\)]+\z/ }
  validates :primary_contact_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: true
  validates :business_address, presence: true
  
  validates :base_delivery_rate, presence: true, numericality: { greater_than: 0 }
  validates :per_km_rate, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :minimum_order_value, numericality: { greater_than_or_equal_to: 0 }
  validates :free_delivery_threshold, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :max_delivery_radius_km, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 200 }
  validates :estimated_prep_time_minutes, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 480 }
  
  validates :business_payment_percentage, numericality: { in: 0.0..100.0 }, if: :split_payment?
  validates :customer_rating, numericality: { in: 1.0..5.0 }, allow_nil: true
  
  # Callbacks
  before_validation :set_default_rates, on: :create
  before_validation :geocode_business_address, if: :should_geocode_address?
  after_update :update_delivery_analytics, if: :saved_change_to_status?
  
  # Scopes
  scope :active, -> { where(status: :active) }
  scope :by_business_type, ->(type) { where(business_type: type) }
  scope :by_fleet_provider, ->(provider) { where(fleet_provider: provider) }
  scope :recently_onboarded, -> { where('activated_at > ?', 30.days.ago) }
  scope :high_volume, -> { where('total_deliveries_count > ?', 100) }
  scope :top_rated, -> { where('customer_rating >= ?', 4.0) }
  scope :near_location, ->(lat, lng, radius_km = 50) {
    where(
      "(6371 * acos(cos(radians(?)) * cos(radians(business_latitude)) * cos(radians(business_longitude) - radians(?)) + sin(radians(?)) * sin(radians(business_latitude)))) <= ?",
      lat, lng, lat, radius_km
    )
  }
  
  # Business Types
  BUSINESS_TYPES = [
    'restaurant',
    'fast_food',
    'cafe',
    'bakery',
    'grocery_store',
    'pharmacy',
    'warehouse',
    'retail_store',
    'flower_shop',
    'electronics',
    'clothing',
    'bookstore',
    'other'
  ].freeze
  
  # Payment Terms
  PAYMENT_TERMS = [
    'immediate',
    'net_7',
    'net_15',
    'net_30',
    'net_45',
    'net_60'
  ].freeze
  
  def full_contact_info
    "#{primary_contact_name} <#{primary_contact_email}>"
  end
  
  def display_name
    business_name
  end
  
  def active?
    status == 'active'
  end
  
  def can_place_orders?
    active? && within_operating_hours?
  end
  
  def within_operating_hours?
    return true unless operating_hours.present?
    
    current_time = Time.current.in_time_zone(timezone)
    day_name = current_time.strftime('%A').downcase
    
    return true unless operating_hours[day_name]
    
    hours = operating_hours[day_name]
    return false if hours['closed'] || hours['open'].blank? || hours['close'].blank?
    
    open_time = Time.parse("#{hours['open']} #{timezone}")
    close_time = Time.parse("#{hours['close']} #{timezone}")
    
    current_time.between?(open_time, close_time)
  end
  
  def calculate_delivery_fee(distance_km, order_value = 0)
    # Check if eligible for free delivery
    if free_delivery_threshold.present? && order_value >= free_delivery_threshold
      return 0.0
    end
    
    # Check for custom pricing rules first
    rule = customer_pricing_rules.active.for_distance(distance_km).first
    return rule.calculate_fee(distance_km) if rule
    
    # Use default rates
    base_fee = base_delivery_rate || fleet_provider.base_delivery_rate
    km_rate = per_km_rate || fleet_provider.per_km_rate
    
    total_fee = base_fee + (distance_km * km_rate)
    
    # Apply minimum order value surcharge if needed
    if minimum_order_value > 0 && order_value < minimum_order_value
      surcharge = [(minimum_order_value - order_value) * 0.1, 5.0].min
      total_fee += surcharge
    end
    
    total_fee.round(2)
  end
  
  def split_delivery_fee(total_fee)
    case default_payment_method
    when 'customer_pays'
      { business_amount: 0.0, customer_amount: total_fee }
    when 'business_pays'
      { business_amount: total_fee, customer_amount: 0.0 }
    when 'split_payment'
      business_amount = (total_fee * business_payment_percentage / 100.0).round(2)
      customer_amount = (total_fee - business_amount).round(2)
      { business_amount: business_amount, customer_amount: customer_amount }
    else
      { business_amount: 0.0, customer_amount: total_fee }
    end
  end
  
  def distance_from(latitude, longitude)
    return nil unless business_latitude && business_longitude
    
    Geocoder::Calculations.distance_between(
      [business_latitude, business_longitude],
      [latitude, longitude],
      units: :km
    )
  end
  
  def within_delivery_radius?(latitude, longitude)
    distance = distance_from(latitude, longitude)
    return false unless distance
    
    distance <= max_delivery_radius_km
  end
  
  def update_analytics!
    deliveries = delivery_requests.delivered
    
    self.total_deliveries_count = deliveries.count
    self.total_revenue = deliveries.sum(:delivery_fee)
    self.average_order_value = total_deliveries_count > 0 ? (total_revenue / total_deliveries_count) : 0.0
    
    # Note: Customer rating functionality would require a driver_rating column in delivery_requests
    # or a separate ratings table. For now, we'll skip this calculation.
    # self.customer_rating = nil
    
    save!
  end
  
  def activate!
    update!(
      status: :active,
      activated_at: Time.current,
      status_notes: "Activated on #{Time.current.strftime('%Y-%m-%d %H:%M')}"
    )
  end
  
  def suspend!(reason = nil)
    update!(
      status: :suspended,
      suspended_at: Time.current,
      status_notes: reason || "Suspended on #{Time.current.strftime('%Y-%m-%d %H:%M')}"
    )
  end
  
  def generate_customer_id
    "CUS-#{fleet_provider.id.to_s.rjust(3, '0')}-#{id.to_s.rjust(5, '0')}"
  end
  
  def usage_stats
    deliveries = delivery_requests.includes(:driver)
    current_month_deliveries = deliveries.where('requested_at >= ?', 1.month.ago)
    completed_deliveries = deliveries.delivered
    
    {
      total_deliveries: total_deliveries_count,
      monthly_deliveries: current_month_deliveries.count,
      success_rate: total_deliveries_count > 0 ? ((completed_deliveries.count.to_f / total_deliveries_count) * 100).round(1) : 0,
      completed_deliveries: completed_deliveries.count,
      total_revenue: total_revenue.to_f,
      monthly_revenue: current_month_deliveries.sum(:delivery_fee).to_f
    }
  end
  
  private
  
  def set_default_rates
    return unless fleet_provider
    
    self.base_delivery_rate ||= fleet_provider.base_delivery_rate || 5.0
    self.per_km_rate ||= fleet_provider.per_km_rate || 2.0
  end
  
  def should_geocode_address?
    business_address_changed? && (business_latitude.blank? || business_longitude.blank?)
  end
  
  def geocode_business_address
    return unless business_address.present?
    
    begin
      result = GeocodingService.geocode(business_address)
      if result
        self.business_latitude = result[:latitude]
        self.business_longitude = result[:longitude]
        self.business_place_id = result[:place_id]
        self.business_address = result[:formatted_address] if result[:formatted_address].present?
        
        # Extract city, state, country from address components
        if result[:address_components]
          components = result[:address_components]
          self.city = components[:city]
          self.state = components[:state]
          self.country = components[:country]
          self.postal_code = components[:postcode]
        end
      end
    rescue GeocodingService::GeocodingError => e
      Rails.logger.warn("Failed to geocode customer address '#{business_address}': #{e.message}")
      errors.add(:business_address, "could not be found. Please check the address or enter coordinates manually.")
    end
  end
  
  def update_delivery_analytics
    # Update analytics when status changes
    update_analytics! if active?
  end
end