class LocationTracking < ApplicationRecord
  belongs_to :driver
  belongs_to :delivery_request, optional: true

  validates :latitude, :longitude, presence: true
  validates :recorded_at, presence: true
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }

  scope :recent, -> { order(recorded_at: :desc) }
  scope :for_delivery, ->(delivery_request) { where(delivery_request: delivery_request) }
  scope :today, -> { where(recorded_at: Date.current.beginning_of_day..Date.current.end_of_day) }
  scope :within_timeframe, ->(start_time, end_time) { where(recorded_at: start_time..end_time) }

  after_create :broadcast_location_update

  def coordinates
    [latitude, longitude]
  end

  def to_geojson
    {
      type: "Feature",
      geometry: {
        type: "Point",
        coordinates: [longitude, latitude]
      },
      properties: {
        driver_id: driver_id,
        delivery_request_id: delivery_request_id,
        recorded_at: recorded_at.iso8601,
        speed: speed,
        bearing: bearing,
        accuracy: accuracy
      }
    }
  end

  private

  def broadcast_location_update
    # Broadcast to driver's location channel
    ActionCable.server.broadcast(
      "driver_location_#{driver_id}",
      {
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        speed: speed,
        bearing: bearing,
        recorded_at: recorded_at.iso8601
      }
    )

    # Broadcast to delivery request channel if associated
    if delivery_request_id
      ActionCable.server.broadcast(
        "delivery_request_#{delivery_request_id}",
        {
          driver_location: {
            latitude: latitude,
            longitude: longitude,
            accuracy: accuracy,
            speed: speed,
            bearing: bearing,
            updated_at: recorded_at.iso8601
          }
        }
      )
    end
  end
end