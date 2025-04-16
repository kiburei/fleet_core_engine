# Seed sample Vehicle Models for use in Kenya
VehicleModel.create([
  make: 'Toyota', model: "Toyota Hilux", category: "commercial", year: 2020, fuel_type: 'Diesel', capacity: 5, transmission: "Manual", body_type: "pickup", created_at: Time.now, updated_at: Time.now
])
# Seed sample FleetProviders
FleetProvider.create([
  name: 'FleetProvider 1', registration_number: 'FP123456', physical_address: '123 Fleet St, Fleet City, FC 12345', email: 'fleet1@fleet', license_status: 'active', license_expiry_date: Date.today + rand(1..12).months, created_at: Time.now, updated_at: Time.now,
  name: 'FleetProvider 2', registration_number: 'FP654321', physical_address: '456 Fleet Ave, Fleet City, FC 54321', email: 'fleet2@fleet', license_status: 'inactive', license_expiry_date: Date.today - rand(1..12).months, created_at: Time.now, updated_at: Time.now,
  name: 'FleetProvider 3', registration_number: 'FP789012', physical_address: '789 Fleet Blvd, Fleet City, FC 67890', email: 'fleet3@fleet', license_status: 'active', license_expiry_date: Date.today + rand(1..12).months, created_at: Time.now, updated_at: Time.now,
  name: 'FleetProvider 4', registration_number: 'FP210987', physical_address: '321 Fleet Rd, Fleet City, FC 09876', email: 'fleet4@fleet', license_status: 'inactive', license_expiry_date: Date.today - rand(1..12).months, created_at: Time.now, updated_at: Time.now,
  name: 'FleetProvider 5', registration_number: 'FP345678', physical_address: '654 Fleet Ln, Fleet City, FC 56789', email: 'fleet5@fleet', license_status: 'active', license_expiry_date: Date.today + rand(1..12).months, created_at: Time.now, updated_at: Time.now,
  name: 'FleetProvider 6', registration_number: 'FP876543', physical_address: '987 Fleet Ct, Fleet City, FC 67890', email: 'fleet6@fleet', license_status: 'inactive', license_expiry_date: Date.today - rand(1..12).months, created_at: Time.now, updated_at: Time.now,
  name: 'FleetProvider 7', registration_number: 'FP135792', physical_address: '159 Fleet Way, Fleet City, FC 24680', email: 'fleet7@fleet', license_status: 'active', license_expiry_date: Date.today + rand(1..12).months, created_at: Time.now, updated_at: Time.now,
  name: 'FleetProvider 8', registration_number: 'FP246813', physical_address: '753 Fleet Dr, Fleet City, FC 13579', email: 'fleet8@fleet', license_status: 'inactive', license_expiry_date: Date.today - rand(1..12).months, created_at: Time.now, updated_at: Time.now
])
