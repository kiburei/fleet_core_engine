class FleetProvider < ApplicationRecord
  has_one_attached :logo

  has_many :vehicles, dependent: :destroy
  has_many :drivers, dependent: :destroy
  has_many :trips, dependent: :destroy
  has_many :documents, as: :documentable, dependent: :destroy
  has_many :users, dependent: :destroy
  has_many :maintenance, dependent: :destroy
  has_many :incidents, dependent: :destroy
  has_many :fleet_provider_users
  has_many :users, through: :fleet_provider_users
  has_many :delivery_requests, dependent: :destroy

  # Delivery service attributes (to be added in migration)
  # delivery_commission_rate :decimal, default: 0.15
  # is_delivery_enabled :boolean, default: false
  # delivery_radius_km :integer, default: 50
  # min_delivery_fee :decimal, default: 5.0
  # max_delivery_fee :decimal, default: 100.0

  scope :delivery_enabled, -> { where(is_delivery_enabled: true) }

  def available_drivers_for_delivery(pickup_lat, pickup_lng, radius_km = nil)
    search_radius = radius_km || delivery_radius_km || 50
    drivers.available_for_delivery
           .within_radius(pickup_lat, pickup_lng, search_radius)
           .order(:current_latitude, :current_longitude)
  end

  def delivery_fee_for_distance(distance_km)
    base_fee = min_delivery_fee || 5.0
    per_km_rate = 2.0  # This could be configurable
    max_fee = max_delivery_fee || 100.0
    
    calculated_fee = base_fee + (distance_km * per_km_rate)
    [calculated_fee, max_fee].min.round(2)
  end

  resourcify
end
