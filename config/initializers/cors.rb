# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the mobile app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin AJAX requests.

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Allow mobile app origins
    origins 'http://localhost:8100', 'http://localhost:3000', 'https://localhost:8100'
    
    # Allow mobile app capacitor origins
    origins /capacitor:\/\//
    origins /http:\/\/localhost(:[0-9]+)?/
    
    # For production, add your mobile app domains
    # origins 'https://yourapp.com', 'https://app.yourapp.com'

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      expose: ['Authorization'],
      credentials: true
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