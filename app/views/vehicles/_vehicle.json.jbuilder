json.extract! vehicle, :id, :vehicle_model_id, :registration_number, :status, :fleet_provider_id, :created_at, :updated_at
json.url vehicle_url(vehicle, format: :json)
