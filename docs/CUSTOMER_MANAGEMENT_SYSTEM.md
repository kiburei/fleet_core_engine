# Customer Management System

## Overview

We've implemented a comprehensive **Customer Management System** that separates business customers (restaurants, warehouses, etc.) from end recipients. This system enables fleet providers to onboard business clients with custom pricing, payment arrangements, and service agreements.

## Key Concepts

### 🏢 **Business Customers vs End Recipients**
- **Business Customer**: The business entity (restaurant, pharmacy, etc.) that has a contract with the fleet provider
- **End Recipient**: The actual person receiving the delivery (customer's customer)

### 💰 **Flexible Payment Models**
- **Customer Pays**: End recipient pays the delivery fee
- **Business Pays**: Business covers all delivery costs
- **Split Payment**: Costs shared between business and end recipient

### 📊 **Custom Pricing Rules**
- **Per-customer rates**: Different pricing for each business
- **Distance-based tiers**: Different rates for different distances
- **Time-based pricing**: Rush hour surcharges, off-peak discounts
- **Order value thresholds**: Free delivery above certain amounts

## Database Schema

### Customer Table
```sql
customers (
  id, business_name, business_type, business_registration_number,
  primary_contact_name, primary_contact_phone, primary_contact_email,
  business_address, business_latitude, business_longitude, business_place_id,
  operating_hours, timezone, payment_terms, billing_contact_info,
  default_payment_method, business_payment_percentage,
  base_delivery_rate, per_km_rate, minimum_order_value, free_delivery_threshold,
  max_delivery_radius_km, estimated_prep_time_minutes,
  service_settings (cash_on_delivery, card_on_delivery, requires_signature, etc.),
  status (pending_approval, active, inactive, suspended),
  fleet_provider_id, account_manager_id, agreement_details,
  analytics (total_deliveries_count, total_revenue, average_order_value, customer_rating)
)
```

### Customer Pricing Rules Table
```sql
customer_pricing_rules (
  id, customer_id, rule_name, description,
  distance_ranges (min_distance_km, max_distance_km),
  time_constraints (start_time, end_time, applicable_days),
  order_value_ranges (min_order_value, max_order_value),
  pricing_type (flat_rate, per_km, tiered, percentage),
  rates (base_rate, per_km_rate, percentage_rate, tiered_rates),
  validity_period (valid_from, valid_until),
  status and priority
)
```

### Updated Delivery Requests
```sql
delivery_requests (
  -- Changed from customer_id to business_customer_id
  business_customer_id (references customers table),
  
  -- Added end recipient information
  end_customer_name, end_customer_phone, end_customer_email,
  
  -- Added order information
  order_value, order_items_count, special_instructions,
  
  -- Added payment split information
  business_payment_amount, customer_payment_amount, payment_method,
  
  -- Existing fields remain the same...
)
```

## Business Features

### 🎯 **Customer Onboarding**
1. **Business Registration**: Complete business profile with address, contacts, legal info
2. **Service Configuration**: Delivery radius, operating hours, service preferences
3. **Pricing Setup**: Custom rates, payment terms, minimum order values
4. **Agreement Management**: Contract terms, special clauses, approval workflow

### 📈 **Pricing & Payment Management**
```ruby
# Example: Restaurant with custom pricing
customer = Customer.find(1)
distance = 5.2 # km
order_value = 45.50

# Calculate delivery fee using custom rules
delivery_fee = customer.calculate_delivery_fee(distance, order_value)

# Split payment based on customer settings
payment_split = customer.split_delivery_fee(delivery_fee)
# => { business_amount: 3.50, customer_amount: 6.50 }
```

### 🕐 **Operating Hours & Business Logic**
```ruby
# Check if customer can place orders
customer.can_place_orders?
# => Checks: active status + within operating hours

# Check delivery radius compliance  
customer.within_delivery_radius?(lat, lng)
# => true/false based on customer's max_delivery_radius_km
```

### 📊 **Analytics & Reporting**
- **Per-customer metrics**: Total deliveries, revenue, average order value
- **Performance ratings**: Driver ratings for each customer
- **Business insights**: Peak hours, delivery patterns, profitability

## API Examples

### Creating a Delivery with Business Customer
```ruby
# POST /delivery_requests
{
  business_customer_id: 123,
  end_customer_name: "John Doe",
  end_customer_phone: "+1234567890",
  end_customer_email: "john@example.com",
  pickup_address: "Pizza Palace, 123 Main St",
  delivery_address: "456 Oak Ave, Apartment 2B",
  order_value: 28.50,
  order_items_count: 3,
  payment_method: "cash",
  special_instructions: "Leave at door, ring doorbell"
}
```

### Customer Pricing Rules
```ruby
# Create a custom pricing rule
CustomerPricingRule.create!(
  customer: customer,
  rule_name: "Happy Hour Discount",
  min_distance_km: 0,
  max_distance_km: 10,
  start_time: "15:00",
  end_time: "17:00",
  applicable_days: ["monday", "tuesday", "wednesday"],
  pricing_type: "per_km",
  base_rate: 3.00,
  per_km_rate: 1.50,
  priority: 10
)
```

## User Interface

### 📋 **Customer Management Dashboard**
- **List View**: Filterable by status, business type, fleet provider
- **Customer Profile**: Complete business information, delivery history
- **Pricing Management**: Configure rates, rules, and payment terms
- **Analytics**: Performance metrics and delivery insights

### 🚚 **Enhanced Delivery Creation**
- **Business Selection**: Choose from active business customers
- **Order Details**: Order value, item count, payment method
- **Recipient Info**: End customer contact details
- **Smart Pricing**: Automatic fee calculation based on customer rules
- **Payment Split**: Visual indication of who pays what

### 📊 **Reporting & Analytics**
- **Customer Performance**: Revenue, delivery volume, ratings
- **Pricing Analysis**: Rule effectiveness, profitability
- **Geographic Insights**: Delivery patterns, coverage areas

## Business Benefits

### 💼 **For Fleet Providers**
1. **Professional B2B Relationships**: Proper business contracts and agreements
2. **Flexible Pricing**: Customize rates per customer and scenario
3. **Payment Security**: Clear payment responsibilities and terms
4. **Business Intelligence**: Deep insights into customer performance
5. **Scalable Operations**: Structured onboarding and management

### 🏪 **For Business Customers**
1. **Custom Service**: Tailored pricing and delivery preferences
2. **Operating Hours**: Deliveries only when business is open
3. **Payment Flexibility**: Choose who pays delivery fees
4. **Service Guarantees**: SLA agreements and performance tracking
5. **Analytics**: Insights into their own delivery patterns

### 👥 **For End Customers**
1. **Reliable Service**: Professional delivery management
2. **Clear Pricing**: Transparent who pays what
3. **Better Tracking**: Business-grade delivery tracking
4. **Quality Assurance**: SLA-backed service levels

## Usage Examples

### 🍕 **Restaurant Scenario**
```ruby
# Pizza Palace setup
pizza_palace = Customer.create!(
  business_name: "Pizza Palace",
  business_type: "restaurant",
  business_address: "123 Main St, Downtown",
  primary_contact_name: "Tony Soprano",
  primary_contact_email: "tony@pizzapalace.com",
  primary_contact_phone: "+1555-PIZZA",
  default_payment_method: "customer_pays", # Customers pay delivery
  base_delivery_rate: 4.99,
  per_km_rate: 1.25,
  free_delivery_threshold: 25.00, # Free delivery over $25
  max_delivery_radius_km: 15,
  estimated_prep_time_minutes: 25,
  allows_cash_on_delivery: true,
  operating_hours: {
    "monday" => { "open" => "11:00", "close" => "23:00" },
    "tuesday" => { "open" => "11:00", "close" => "23:00" },
    # ... rest of week
  }
)
```

### 🏥 **Pharmacy Scenario**
```ruby
# Medical supplies with business paying delivery
med_supply = Customer.create!(
  business_name: "QuickMed Pharmacy",
  business_type: "pharmacy",
  default_payment_method: "business_pays", # Business covers all costs
  requires_signature: true, # Prescription deliveries
  allows_contactless_delivery: false,
  base_delivery_rate: 8.50, # Premium rate for medical
  minimum_order_value: 15.00,
  max_delivery_radius_km: 25
)
```

### 📦 **Warehouse Scenario**
```ruby
# B2B warehouse with split payments
warehouse = Customer.create!(
  business_name: "MegaStore Warehouse",
  business_type: "warehouse",
  default_payment_method: "split_payment",
  business_payment_percentage: 70.0, # Business pays 70%, customer pays 30%
  base_delivery_rate: 12.00,
  per_km_rate: 2.50,
  max_delivery_radius_km: 50, # Wider coverage
  estimated_prep_time_minutes: 60 # Longer prep time
)
```

## Integration Points

### 🔗 **Existing Systems**
- **Fleet Providers**: Each customer belongs to a fleet provider
- **Delivery Requests**: Enhanced with customer and recipient separation
- **Driver App**: Shows business info + end recipient details
- **Notifications**: Separate notifications for business and recipients

### 🌐 **External Integrations**
- **Accounting Systems**: Proper business invoicing and payment tracking
- **POS Systems**: Integration with restaurant/retail point-of-sale
- **Business Management**: CRM-style customer relationship management

## Getting Started

### 1. **Create Your First Customer**
```bash
# Navigate to customers section
curl -X POST http://localhost:3001/customers \
  -d "customer[business_name]=Demo Restaurant" \
  -d "customer[business_type]=restaurant" \
  -d "customer[primary_contact_email]=demo@restaurant.com" \
  # ... other fields
```

### 2. **Set Up Pricing Rules**
```bash
# Create a custom pricing rule
curl -X POST http://localhost:3001/customers/1/pricing_rules \
  -d "pricing_rule[rule_name]=Weekend Premium" \
  -d "pricing_rule[base_rate]=6.99" \
  -d "pricing_rule[applicable_days][]=saturday" \
  -d "pricing_rule[applicable_days][]=sunday"
```

### 3. **Create Deliveries**
```bash
# Create delivery with business customer
curl -X POST http://localhost:3001/delivery_requests \
  -d "delivery_request[business_customer_id]=1" \
  -d "delivery_request[end_customer_name]=John Doe" \
  -d "delivery_request[order_value]=32.50" \
  # ... other fields
```

## Migration Guide

### From Previous System
1. **Run Migrations**: `rails db:migrate`
2. **Create Test Customer**: Set up your first business customer
3. **Update Forms**: Existing delivery forms now use business customers
4. **Test Pricing**: Verify automatic fee calculation works
5. **Import Data**: Migrate existing customers to new structure

### Data Migration Strategy
```ruby
# Example migration script for existing customers
User.where(role: 'customer').find_each do |user|
  Customer.create!(
    business_name: user.company_name || user.name,
    business_type: 'other',
    primary_contact_name: user.name,
    primary_contact_email: user.email,
    primary_contact_phone: user.phone,
    business_address: user.address,
    fleet_provider: user.default_fleet_provider,
    status: 'active'
  )
end
```

This customer management system transforms the delivery service from a simple point-to-point service into a comprehensive B2B delivery platform with enterprise-grade features and flexibility.