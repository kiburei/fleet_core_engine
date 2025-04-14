json.extract! fleet_provider, :id, :name, :registration_number, :physical_address, :phone_number, :email, :license_status, :license_expiry_date, :created_at, :updated_at
json.url fleet_provider_url(fleet_provider, format: :json)
