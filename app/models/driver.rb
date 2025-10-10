class Driver < ApplicationRecord
  has_one_attached :profile_picture

  belongs_to :user, optional: true
  belongs_to :vehicle, optional: true
  belongs_to :fleet_provider

  has_many :trips
  has_many :incidents
  has_many :documents, as: :documentable, dependent: :destroy
  
  # Delivery-specific associations
  has_many :delivery_requests, dependent: :nullify
  has_many :location_trackings, dependent: :destroy
  has_many :assigned_deliveries, -> { where.not(driver_id: nil) }, class_name: 'DeliveryRequest'
  has_many :completed_deliveries, -> { where(status: 'delivered') }, class_name: 'DeliveryRequest'

  # Geocoding
  geocoded_by :address, latitude: :current_latitude, longitude: :current_longitude

  # Validations
  validates :phone_number, presence: true, if: :is_available_for_delivery?
  validates :current_latitude, :current_longitude, presence: true, if: :is_online?

  # Scopes
  scope :available_for_delivery, -> { where(is_available_for_delivery: true, is_online: true) }
  scope :available, -> { where(is_online: true, is_available_for_delivery: true) }
  scope :online, -> { where(is_online: true) }
  scope :offline, -> { where(is_online: false) }
  scope :busy, -> { joins(:delivery_requests).where(delivery_requests: { status: ['assigned', 'picked_up', 'in_transit'] }).distinct }
  scope :recent, -> { order(created_at: :desc) }
  scope :within_radius, ->(lat, lng, radius_km) {
    where(
      "(6371 * acos(cos(radians(?)) * cos(radians(current_latitude)) * cos(radians(current_longitude) - radians(?)) + sin(radians(?)) * sin(radians(current_latitude)))) <= ?",
      lat, lng, lat, radius_km
    ).where.not(current_latitude: nil, current_longitude: nil)
  }

  def full_name
    [ first_name, middle_name, last_name ].compact.join(" ")
  end
  
  def phone
    phone_number
  end

  def current_location
    return nil unless current_latitude && current_longitude
    [current_latitude, current_longitude]
  end

  def update_location(lat, lng, accuracy = nil, speed = nil, bearing = nil)
    update!(
      current_latitude: lat,
      current_longitude: lng,
      last_location_update: Time.current
    )
    
    # Record location tracking
    location_trackings.create!(
      latitude: lat,
      longitude: lng,
      accuracy: accuracy,
      speed: speed,
      bearing: bearing,
      recorded_at: Time.current,
      delivery_request: current_delivery
    )
  end

  def current_delivery
    delivery_requests.where(status: ['assigned', 'picked_up']).first
  end
  
  alias_method :current_delivery_request, :current_delivery

  def available_for_new_delivery?
    is_available_for_delivery? && is_online? && current_delivery.nil?
  end

  def distance_to(lat, lng)
    return nil unless current_latitude && current_longitude
    
    # Haversine formula for distance calculation
    rad_per_deg = Math::PI / 180
    rkm = 6371  # Earth radius in kilometers
    rm = rkm * 1000  # Earth radius in meters

    dlat_rad = (lat - current_latitude) * rad_per_deg
    dlon_rad = (lng - current_longitude) * rad_per_deg

    lat1_rad = current_latitude * rad_per_deg
    lat2_rad = lat * rad_per_deg

    a = Math.sin(dlat_rad/2)**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(dlon_rad/2)**2
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))

    rkm * c  # Distance in kilometers
  end

  def average_rating
    delivery_rating
  end

  def can_accept_delivery?(delivery_request)
    return false unless available_for_new_delivery?
    return false if distance_to(delivery_request.pickup_latitude, delivery_request.pickup_longitude) > max_delivery_distance_km
    true
  end
end
