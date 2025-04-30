# db/seeds.rb

# Seed sample Vehicle Models for use in Kenya
VehicleModel.create!([
  { make: 'Toyota', model: "Toyota Hilux", category: "commercial", year: 2020, fuel_type: 'Diesel', capacity: 5, transmission: "Manual", body_type: "pickup" },
  { make: 'Toyota', model: "Toyota Land Cruiser", category: "commercial", year: 2021, fuel_type: 'Diesel', capacity: 7, transmission: "Automatic", body_type: "SUV" },
  { make: 'Toyota', model: "Toyota Corolla", category: "passenger", year: 2019, fuel_type: 'Petrol', capacity: 5, transmission: "Automatic", body_type: "sedan" },
  { make: 'Nissan', model: "Nissan Navara", category: "commercial", year: 2020, fuel_type: 'Diesel', capacity: 5, transmission: "Manual", body_type: "pickup" },
  { make: 'Nissan', model: "Nissan Patrol", category: "commercial", year: 2021, fuel_type: 'Diesel', capacity: 7, transmission: "Automatic", body_type: "SUV" },
  { make: 'Nissan', model: "Nissan Almera", category: "passenger", year: 2019, fuel_type: 'Petrol', capacity: 5, transmission: "Automatic", body_type: "sedan" },
  { make: 'Honda', model: "Honda CR-V", category: "commercial", year: 2020, fuel_type: 'Petrol', capacity: 5, transmission: "Automatic", body_type: "SUV" },
  { make: 'Honda', model: "Honda Accord", category: "passenger", year: 2021, fuel_type: 'Petrol', capacity: 5, transmission: "Automatic", body_type: "sedan" },
  { make: 'Honda', model: "Honda Fit", category: "passenger", year: 2019, fuel_type: 'Petrol', capacity: 5, transmission: "Automatic", body_type: "hatchback" },
  { make: 'Mitsubishi', model: "Mitsubishi L200", category: "commercial", year: 2020, fuel_type: 'Diesel', capacity: 5, transmission: "Manual", body_type: "pickup" },
  { make: 'Mitsubishi', model: "Mitsubishi Pajero", category: "commercial", year: 2021, fuel_type: 'Diesel', capacity: 7, transmission: "Automatic", body_type: "SUV" },
  { make: 'Mitsubishi', model: "Mitsubishi Outlander", category: "passenger", year: 2019, fuel_type: 'Petrol', capacity: 5, transmission: "Automatic", body_type: "SUV" },
  { make: 'Subaru', model: "Subaru Outback", category: "commercial", year: 2020, fuel_type: 'Petrol', capacity: 5, transmission: "Automatic", body_type: "SUV" },
  { make: 'Subaru', model: "Subaru Forester", category: "commercial", year: 2021, fuel_type: 'Petrol', capacity: 5, transmission: "Automatic", body_type: "SUV" },
  { make: 'Subaru', model: "Subaru Legacy", category: "passenger", year: 2019, fuel_type: 'Petrol', capacity: 5, transmission: "Automatic", body_type: "sedan" },
  { make: 'Mercedes-Benz', model: "Mercedes-Benz G-Class", category: "commercial", year: 2020, fuel_type: 'Diesel', capacity: 5, transmission: "Automatic", body_type: "SUV" },
  { make: 'Mercedes-Benz', model: "Mercedes-Benz E-Class", category: "passenger", year: 2021, fuel_type: 'Diesel', capacity: 5, transmission: "Automatic", body_type: "sedan" },
  { make: 'Mercedes-Benz', model: "Mercedes-Benz C-Class", category: "passenger", year: 2019, fuel_type: 'Diesel', capacity: 5, transmission: "Automatic", body_type: "sedan" },
  { make: 'BMW', model: "BMW X5", category: "commercial", year: 2020, fuel_type: 'Diesel', capacity: 5, transmission: "Automatic", body_type: "SUV" },
  { make: 'BMW', model: "BMW 5 Series", category: "passenger", year: 2021, fuel_type: 'Diesel', capacity: 5, transmission: "Automatic", body_type: "sedan" },
  { make: 'BMW', model: "BMW 3 Series", category: "passenger", year: 2019, fuel_type: 'Diesel', capacity: 5, transmission: "Automatic", body_type: "sedan" },
  { make: 'Ford', model: "Ford Ranger", category: "commercial", year: 2020, fuel_type: 'Diesel', capacity: 5, transmission: "Manual", body_type: "pickup" },
  { make: 'Ford', model: "Ford Everest", category: "commercial", year: 2021, fuel_type: 'Diesel', capacity: 7, transmission: "Automatic", body_type: "SUV" },
  { make: 'Ford', model: "Ford Focus", category: "passenger", year: 2019, fuel_type: 'Petrol', capacity: 5, transmission: "Automatic", body_type: "hatchback" }
])

# Seed sample Fleet Providers
FleetProvider.create!([
  { name: 'Magari Africa', registration_number: 'FP123456', physical_address: '123 Fleet St, Fleet City', email: 'fleet1@fleet.com', license_status: 'active', license_expiry_date: Date.today + 6.months },
  { name: 'Green Park Rentals', registration_number: 'FP654321', physical_address: '456 Fleet Ave, Fleet City', email: 'fleet2@fleet.com', license_status: 'inactive', license_expiry_date: Date.today - 3.months },
  { name: 'Mololine Sacco', registration_number: 'FP789012', physical_address: '789 Fleet Blvd, Fleet City', email: 'fleet3@fleet.com', license_status: 'active', license_expiry_date: Date.today + 9.months },
  { name: 'Supermetro Sacco', registration_number: 'FP210987', physical_address: '321 Fleet Rd, Fleet City', email: 'fleet4@fleet.com', license_status: 'inactive', license_expiry_date: Date.today - 2.months },
  { name: 'All Saints Cathedral', registration_number: 'FP345678', physical_address: '654 Fleet Ln, Fleet City', email: 'fleet5@fleet.com', license_status: 'active', license_expiry_date: Date.today + 4.months },
  { name: 'Electric Fleet', registration_number: 'FP876543', physical_address: '987 Fleet Ct, Fleet City', email: 'fleet6@fleet.com', license_status: 'inactive', license_expiry_date: Date.today - 5.months },
  { name: 'Group of Schools Fleet', registration_number: 'FP135792', physical_address: '159 Fleet Way, Fleet City', email: 'fleet7@fleet.com', license_status: 'active', license_expiry_date: Date.today + 7.months },
  { name: 'Company Fleet', registration_number: 'FP246813', physical_address: '753 Fleet Dr, Fleet City', email: 'fleet8@fleet.com', license_status: 'inactive', license_expiry_date: Date.today - 6.months }
])
