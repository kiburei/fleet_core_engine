# Seed roles
puts "Creating roles..."
[
  'admin',
  'fleet_provider_admin',
  'fleet_provider_manager',
  'fleet_provider_owner',
  'fleet_provider_user',
  'fleet_provider_driver',
  'service_provider'
].each do |role_name|
  if Role.exists?(name: role_name)
    puts "✓ Role '#{role_name}' already exists"
  else
    Role.create!(name: role_name)
    puts "✓ Role '#{role_name}' created"
  end
end

# Seed admin user
puts "\nCreating admin user..."
admin_user = User.find_or_create_by(email: 'admin@admin') do |user|
  user.first_name = 'Admin'
  user.last_name = 'User'
  user.password = 'password'
  user.password_confirmation = 'password'
  user.phone_number = '0712345678'
  user.fleet_provider_id = nil
end

# Assign admin role to the admin user
if admin_user.persisted?
  admin_user.add_role(:admin) unless admin_user.has_role?(:admin)
  puts "✓ Admin user created/updated and admin role assigned"
end


# Seed sample Vehicle Models for use in Kenya
puts "\nCreating vehicle models..."
vehicle_models = [
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
]

vehicle_models.each do |vm_attrs|
  if VehicleModel.exists?(make: vm_attrs[:make], model: vm_attrs[:model])
    puts "✓ Vehicle model '#{vm_attrs[:model]}' already exists"
  else
    VehicleModel.create!(vm_attrs)
    puts "✓ Vehicle model '#{vm_attrs[:model]}' created"
  end
end

# Seed sample Fleet Providers
puts "\nCreating fleet providers..."
fleet_providers = [
  { name: 'Magari Africa', registration_number: 'FP123456', physical_address: '123 Fleet St, Fleet City', email: 'fleet1@fleet.com', license_status: 'active', license_expiry_date: Date.today + 6.months },
  { name: 'Green Park Rentals', registration_number: 'FP654321', physical_address: '456 Fleet Ave, Fleet City', email: 'fleet2@fleet.com', license_status: 'inactive', license_expiry_date: Date.today - 3.months },
  { name: 'Mololine Sacco', registration_number: 'FP789012', physical_address: '789 Fleet Blvd, Fleet City', email: 'fleet3@fleet.com', license_status: 'active', license_expiry_date: Date.today + 9.months },
  { name: 'Supermetro Sacco', registration_number: 'FP210987', physical_address: '321 Fleet Rd, Fleet City', email: 'fleet4@fleet.com', license_status: 'inactive', license_expiry_date: Date.today - 2.months },
  { name: 'All Saints Cathedral', registration_number: 'FP345678', physical_address: '654 Fleet Ln, Fleet City', email: 'fleet5@fleet.com', license_status: 'active', license_expiry_date: Date.today + 4.months },
  { name: 'Electric Fleet', registration_number: 'FP876543', physical_address: '987 Fleet Ct, Fleet City', email: 'fleet6@fleet.com', license_status: 'inactive', license_expiry_date: Date.today - 5.months },
  { name: 'Group of Schools Fleet', registration_number: 'FP135792', physical_address: '159 Fleet Way, Fleet City', email: 'fleet7@fleet.com', license_status: 'active', license_expiry_date: Date.today + 7.months },
  { name: 'Company Fleet', registration_number: 'FP246813', physical_address: '753 Fleet Dr, Fleet City', email: 'fleet8@fleet.com', license_status: 'inactive', license_expiry_date: Date.today - 6.months }
]

fleet_providers.each do |fp_attrs|
  if FleetProvider.exists?(registration_number: fp_attrs[:registration_number])
    puts "✓ Fleet provider '#{fp_attrs[:name]}' already exists"
  else
    FleetProvider.create!(fp_attrs)
    puts "✓ Fleet provider '#{fp_attrs[:name]}' created"
  end
end

# Seed sample marketplace products
puts "\nCreating marketplace products..."

# Get admin user for product ownership
admin_user = User.find_by(email: 'admin@admin')

if admin_user
  sample_products = [
    {
      name: "GPS Fleet Tracking System",
      description: "Advanced real-time vehicle tracking with route optimization, driver behavior monitoring, and detailed reporting dashboard. Perfect for fleet management and operational efficiency.",
      price: 15000,
      category: "tracking",
      target_audience: "fleet_owners",
      active: true,
      featured: true,
      tags: "gps, tracking, fleet, monitoring, real-time",
      user: admin_user
    },
    {
      name: "Comprehensive Fleet Insurance Package",
      description: "Complete insurance coverage for your entire fleet including third-party, comprehensive, and cargo insurance. Special rates for fleet owners.",
      price: 45000,
      category: "insurance",
      target_audience: "fleet_owners",
      active: true,
      featured: true,
      tags: "insurance, coverage, fleet, protection, comprehensive",
      user: admin_user
    },
    {
      name: "Professional Driver Training Course",
      description: "Certified defensive driving course with emphasis on safety, fuel efficiency, and customer service. Includes certificate upon completion.",
      price: 8500,
      category: "training",
      target_audience: "drivers",
      active: true,
      featured: false,
      tags: "training, safety, drivers, certification, course",
      user: admin_user
    },
    {
      name: "Vehicle Maintenance Management Software",
      description: "Digital solution for tracking maintenance schedules, costs, and service history. Automated reminders and detailed analytics included.",
      price: 12000,
      category: "software",
      target_audience: "managers",
      active: true,
      featured: false,
      tags: "software, maintenance, tracking, analytics, digital",
      user: admin_user
    },
    {
      name: "Emergency Roadside Assistance",
      description: "24/7 emergency roadside assistance including towing, battery jump-start, tire change, and emergency fuel delivery across major highways.",
      price: 25000,
      category: "emergency",
      target_audience: "all",
      active: true,
      featured: true,
      tags: "emergency, roadside, assistance, towing, 24/7",
      user: admin_user
    },
    {
      name: "Fuel Management System",
      description: "Smart fuel monitoring system with fuel card integration, consumption tracking, and theft prevention. Real-time fuel level monitoring.",
      price: 18000,
      category: "fuel",
      target_audience: "fleet_owners",
      active: true,
      featured: false,
      tags: "fuel, management, monitoring, cards, efficiency",
      user: admin_user
    },
    {
      name: "Driver Safety Equipment Bundle",
      description: "Complete safety kit including reflective vests, first aid kit, emergency triangles, fire extinguisher, and safety manual.",
      price: 3500,
      category: "safety",
      target_audience: "drivers",
      active: true,
      featured: false,
      tags: "safety, equipment, emergency, protection, bundle",
      user: admin_user
    },
    {
      name: "Fleet Analytics Dashboard",
      description: "Advanced analytics platform providing insights on fleet performance, cost optimization, driver behavior, and operational efficiency metrics.",
      price: 22000,
      category: "software",
      target_audience: "managers",
      active: false,
      featured: false,
      tags: "analytics, dashboard, insights, performance, metrics",
      user: admin_user
    }
  ]
  
  sample_products.each do |product_attrs|
    if Marketplace::Product.exists?(name: product_attrs[:name])
      puts "✓ Product '#{product_attrs[:name]}' already exists"
    else
      Marketplace::Product.create!(product_attrs)
      puts "✓ Product '#{product_attrs[:name]}' created"
    end
  end
else
  puts "⚠ Admin user not found, skipping marketplace products"
end

puts "\n✓ Seeds completed successfully!"
