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
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }, if: :should_create_user_account?
  
  # Callbacks
  before_validation :set_email_from_phone, if: :should_auto_generate_email?
  after_create :create_user_account, if: :should_create_user_account?
  after_update :update_user_account, if: :should_update_user_account?

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

  # User account management methods
  def has_user_account?
    user.present?
  end

  def can_login?
    has_user_account? && user.email.present?
  end

  def create_user_account!
    return user if user.present?
    
    email_to_use = email.presence || generate_email_from_phone
    password = generate_temporary_password
    
    new_user = User.create!(
      email: email_to_use,
      password: password,
      password_confirmation: password,
      first_name: first_name,
      last_name: last_name,
      phone: phone_number
    )
    
    # Assign driver role
    new_user.add_role(:fleet_provider_driver)
    
    # Link the user to this driver
    update!(user: new_user, email: email_to_use)
    
    # Store the temporary password for sending to the driver
    @temporary_password = password
    
    new_user
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to create user account for driver #{id}: #{e.message}"
    raise e
  end

  def generate_temporary_password
    SecureRandom.hex(8)
  end

  def temporary_password
    @temporary_password
  end

  def send_login_credentials
    return unless user.present? && @temporary_password.present?
    
    # Here you would send SMS or email with login credentials
    # For now, we'll just log it (in production, integrate with your SMS/email service)
    Rails.logger.info "Driver #{full_name} login credentials: Email: #{user.email}, Password: #{@temporary_password}"
    
    # You can integrate with services like:
    # - Twilio for SMS
    # - ActionMailer for email
    # - Push notifications
    
    # Example SMS integration (uncomment and configure as needed):
    # DriverCredentialsSmsJob.perform_later(self, @temporary_password)
    
    # Example email integration:
    # DriverMailer.login_credentials(self, @temporary_password).deliver_later
  end

  def reset_password!
    return unless user.present?
    
    new_password = generate_temporary_password
    user.update!(
      password: new_password,
      password_confirmation: new_password
    )
    
    @temporary_password = new_password
    send_login_credentials
    
    new_password
  end

  def deactivate_user_account!
    return unless user.present?
    
    # Remove driver role - this prevents API access
    user.remove_role(:fleet_provider_driver)
    
    # Update driver status to reflect deactivation
    update!(is_online: false, is_available_for_delivery: false)
  end

  def reactivate_user_account!
    return unless user.present?
    
    # Restore driver role
    user.add_role(:fleet_provider_driver) unless user.has_role?(:fleet_provider_driver)
  end

  private

  def should_create_user_account?
    create_user_account == true || create_user_account == '1'
  end

  def should_auto_generate_email?
    should_create_user_account? && email.blank? && phone_number.present?
  end

  def should_update_user_account?
    user.present? && (saved_change_to_first_name? || saved_change_to_last_name? || saved_change_to_phone_number?)
  end

  def set_email_from_phone
    self.email = generate_email_from_phone if email.blank?
  end

  def generate_email_from_phone
    return nil unless phone_number.present?
    
    # Clean phone number (remove non-digits)
    clean_phone = phone_number.gsub(/\D/, '')
    
    # Generate email: phone@fleet-provider-name.drivers
    fleet_name = fleet_provider.name.downcase.gsub(/\s+/, '-').gsub(/[^a-z0-9\-]/, '')
    "#{clean_phone}@#{fleet_name}.drivers"
  end

  def create_user_account
    create_user_account!
    send_login_credentials
  rescue => e
    Rails.logger.error "Failed to create user account for driver #{id}: #{e.message}"
    # Don't raise the error to prevent driver creation from failing
  end

  def update_user_account
    return unless user.present?
    
    user.update!(
      first_name: first_name,
      last_name: last_name,
      phone: phone_number
    )
  rescue => e
    Rails.logger.error "Failed to update user account for driver #{id}: #{e.message}"
  end
end
