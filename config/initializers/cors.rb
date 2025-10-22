# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the mobile app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin AJAX requests.

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Development origins, mobile app capacitor origins, and production domains
    origins 'http://localhost:8100', 
            'http://localhost:3000', 
            'https://localhost:3000', 
            'https://localhost:8100',
            'https://delivery.matean.online', 
            'https://fleet.matean.online',
            /capacitor:\/\//,
            /http:\/\/localhost(:[0-9]+)?/

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      expose: ['Authorization', 'Content-Type', 'X-Requested-With'],
      credentials: true
  end
  
  # Specific configuration for API endpoints
  allow do
    origins 'https://delivery.matean.online', 'https://fleet.matean.online'
    
    resource '/api/*',
      headers: ['Authorization', 'Content-Type', 'Accept', 'X-Requested-With'],
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      expose: ['Authorization', 'Content-Type'],
      credentials: true,
      max_age: 86400  # Cache preflight for 24 hours
  end
  
  # Allow all origins for ActionCable in development
  if Rails.env.development?
    allow do
      origins '*'
      resource '/cable',
        headers: :any,
        methods: [:get, :post, :patch, :put, :delete, :options],
        credentials: false
    end
  end
end