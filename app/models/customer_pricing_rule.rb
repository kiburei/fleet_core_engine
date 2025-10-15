class CustomerPricingRule < ApplicationRecord
  belongs_to :customer
  
  # Enums
  enum :pricing_type, {
    flat_rate: 0,    # Fixed price regardless of distance
    per_km: 1,       # Base rate + per km rate
    tiered: 2,       # Different rates for different distance tiers
    percentage: 3    # Percentage of order value
  }
  
  # Validations
  validates :rule_name, presence: true, length: { maximum: 255 }
  validates :min_distance_km, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :max_distance_km, numericality: { greater_than: 0 }, allow_nil: true
  validates :base_rate, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :per_km_rate, numericality: { greater_than_or_equal_to: 0 }
  validates :percentage_rate, numericality: { in: 0.0..100.0 }
  validates :priority, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  validate :max_distance_greater_than_min_distance
  validate :valid_time_range
  validate :valid_order_value_range
  validate :valid_tiered_rates_structure
  
  # Callbacks
  after_update :update_usage_tracking, if: :saved_change_to_active?
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_priority, -> { order(priority: :desc) }
  scope :for_distance, ->(distance_km) {
    where('min_distance_km <= ? AND (max_distance_km IS NULL OR max_distance_km >= ?)', distance_km, distance_km)
  }
  scope :for_order_value, ->(order_value) {
    where('(min_order_value IS NULL OR min_order_value <= ?) AND (max_order_value IS NULL OR max_order_value >= ?)', order_value, order_value)
  }
  scope :for_time, ->(time) {
    where('start_time IS NULL OR end_time IS NULL OR (start_time <= ? AND end_time >= ?)', time, time)
  }
  scope :for_day, ->(day_name) {
    where('applicable_days IS NULL OR JSON_CONTAINS(applicable_days, ?)', "\"#{day_name.downcase}\"")
  }
  scope :valid_now, -> { where('(valid_from IS NULL OR valid_from <= ?) AND (valid_until IS NULL OR valid_until >= ?)', Time.current, Time.current) }
  scope :recently_used, -> { where('last_used_at > ?', 30.days.ago) }
  
  def applicable_for?(distance_km, order_value = nil, check_time: true)
    # Check if rule is active and within validity period
    return false unless active?
    return false if valid_from && Time.current < valid_from
    return false if valid_until && Time.current > valid_until
    
    # Check distance range
    return false unless distance_within_range?(distance_km)
    
    # Check order value range
    return false unless order_value_within_range?(order_value) if order_value
    
    # Check time and day constraints
    if check_time
      return false unless time_applicable?
    end
    
    true
  end
  
  def calculate_fee(distance_km, order_value = 0)
    return 0.0 unless applicable_for?(distance_km, order_value)
    
    fee = case pricing_type
          when 'flat_rate'
            base_rate
          when 'per_km'
            base_rate + (distance_km * per_km_rate)
          when 'tiered'
            calculate_tiered_fee(distance_km)
          when 'percentage'
            order_value * (percentage_rate / 100.0)
          else
            base_rate
          end
    
    # Track usage
    increment_usage!
    
    fee.round(2)
  end
  
  def distance_range_text
    if max_distance_km
      "#{min_distance_km} - #{max_distance_km} km"
    else
      "#{min_distance_km}+ km"
    end
  end
  
  def order_value_range_text
    return "Any order value" unless min_order_value || max_order_value
    
    if min_order_value && max_order_value
      "$#{min_order_value} - $#{max_order_value}"
    elsif min_order_value
      "$#{min_order_value}+"
    elsif max_order_value
      "Up to $#{max_order_value}"
    end
  end
  
  def time_range_text
    return "Any time" unless start_time && end_time
    
    "#{start_time.strftime('%H:%M')} - #{end_time.strftime('%H:%M')}"
  end
  
  def applicable_days_text
    return "Any day" unless applicable_days&.any?
    
    applicable_days.map(&:titleize).join(', ')
  end
  
  def pricing_description
    case pricing_type
    when 'flat_rate'
      "$#{base_rate} flat rate"
    when 'per_km'
      "$#{base_rate} base + $#{per_km_rate}/km"
    when 'tiered'
      "Tiered pricing"
    when 'percentage'
      "#{percentage_rate}% of order value"
    end
  end
  
  def usage_stats
    {
      total_usage: usage_count,
      last_used: last_used_at&.strftime('%Y-%m-%d %H:%M'),
      average_monthly_usage: calculate_monthly_usage
    }
  end
  
  private
  
  def distance_within_range?(distance_km)
    return false if distance_km < min_distance_km
    return false if max_distance_km && distance_km > max_distance_km
    true
  end
  
  def order_value_within_range?(order_value)
    return true unless order_value
    return false if min_order_value && order_value < min_order_value
    return false if max_order_value && order_value > max_order_value
    true
  end
  
  def time_applicable?
    current_time = Time.current
    
    # Check day of week
    if applicable_days&.any?
      current_day = current_time.strftime('%A').downcase
      return false unless applicable_days.include?(current_day)
    end
    
    # Check time range
    if start_time && end_time
      current_time_only = current_time.strftime('%H:%M:%S').to_time
      return false unless current_time_only.between?(start_time, end_time)
    end
    
    true
  end
  
  def calculate_tiered_fee(distance_km)
    return base_rate unless tiered_rates&.any?
    
    applicable_tier = tiered_rates.find do |tier|
      min_km = tier['min_km'] || 0
      max_km = tier['max_km']
      
      distance_km >= min_km && (max_km.nil? || distance_km <= max_km)
    end
    
    return base_rate unless applicable_tier
    
    tier_rate = applicable_tier['rate'] || base_rate
    tier_rate.to_f
  end
  
  def increment_usage!
    increment!(:usage_count)
    update_column(:last_used_at, Time.current)
  end
  
  def calculate_monthly_usage
    return 0 unless usage_count > 0 && created_at
    
    months_active = [(Time.current - created_at) / 1.month, 1].max
    (usage_count / months_active).round(1)
  end
  
  # Validation methods
  def max_distance_greater_than_min_distance
    return unless min_distance_km && max_distance_km
    
    if max_distance_km <= min_distance_km
      errors.add(:max_distance_km, 'must be greater than minimum distance')
    end
  end
  
  def valid_time_range
    return unless start_time && end_time
    
    if start_time >= end_time
      errors.add(:end_time, 'must be after start time')
    end
  end
  
  def valid_order_value_range
    return unless min_order_value && max_order_value
    
    if max_order_value <= min_order_value
      errors.add(:max_order_value, 'must be greater than minimum order value')
    end
  end
  
  def valid_tiered_rates_structure
    return unless tiered_rates&.any?
    
    tiered_rates.each_with_index do |tier, index|
      unless tier.is_a?(Hash) && tier['min_km'].present? && tier['rate'].present?
        errors.add(:tiered_rates, "Invalid structure at tier #{index + 1}")
        break
      end
      
      min_km = tier['min_km'].to_f
      max_km = tier['max_km']&.to_f
      rate = tier['rate'].to_f
      
      if rate < 0
        errors.add(:tiered_rates, "Rate cannot be negative at tier #{index + 1}")
        break
      end
      
      if max_km && max_km <= min_km
        errors.add(:tiered_rates, "Max distance must be greater than min distance at tier #{index + 1}")
        break
      end
    end
  end
  
  def update_usage_tracking
    # Reset usage stats if rule is deactivated
    if !active? && usage_count > 0
      update_columns(usage_count: 0, last_used_at: nil)
    end
  end
end