json.extract! trip, :id, :vehicle_id, :driver_id, :origin, :destination, :departure_time, :arrival_time, :status, :created_at, :updated_at
json.url trip_url(trip, format: :json)
