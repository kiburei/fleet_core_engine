# CORS Configuration Fix - Deployment Guide

## Problem
Frontend at `https://delivery.matean.online` is blocked by CORS policy when accessing API at `https://fleet.matean.online/api/v1/auth/login`.

## Changes Made

### 1. Updated CORS Configuration (`config/initializers/cors.rb`)
Added production domains and comprehensive CORS settings:

```ruby
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Development origins
    origins 'http://localhost:8100', 'http://localhost:3000', 'https://localhost:8100'
    
    # Allow mobile app capacitor origins
    origins /capacitor:\/\//
    origins /http:\/\/localhost(:[0-9]+)?/
    
    # Production domains
    origins 'https://delivery.matean.online', 'https://fleet.matean.online'

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
```

### 2. Updated Production Environment (`config/environments/production.rb`)
Added allowed hosts to prevent host header attacks:

```ruby
config.hosts = [
  "fleet.matean.online",     # Allow requests from fleet API
  "delivery.matean.online",  # Allow requests from delivery frontend
  /.*\.matean\.online/       # Allow requests from matean.online subdomains
]
```

### 3. Added CORS Testing Endpoints
Created test endpoints to verify CORS configuration:
- `GET /api/v1/cors/test` - Simple test endpoint
- `OPTIONS /api/v1/cors/test` - Preflight test endpoint

## Deployment Steps

### 1. Deploy to Production
```bash
# Commit the changes
git add .
git commit -m "Fix CORS configuration for production domains"

# Deploy using your deployment method (e.g., Kamal, Capistrano, or direct deployment)
bundle exec kamal deploy
# or your deployment command
```

### 2. Restart the Application
After deployment, ensure the Rails application is restarted so the initializer changes take effect:
```bash
# If using Kamal
bundle exec kamal app exec 'rails runner "puts Rails.env"'

# If using systemd/service
sudo systemctl restart your-app-service

# If using passenger
touch tmp/restart.txt
```

### 3. Test CORS Configuration

#### Test with curl:
```bash
# Test preflight request
curl -X OPTIONS \
  -H "Origin: https://delivery.matean.online" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type,Authorization" \
  -v https://fleet.matean.online/api/v1/auth/login

# Test actual request
curl -X POST \
  -H "Origin: https://delivery.matean.online" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password"}' \
  -v https://fleet.matean.online/api/v1/auth/login

# Test CORS test endpoint
curl -X GET \
  -H "Origin: https://delivery.matean.online" \
  -v https://fleet.matean.online/api/v1/cors/test
```

#### Expected Response Headers:
The response should include these headers:
```
Access-Control-Allow-Origin: https://delivery.matean.online
Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS, HEAD
Access-Control-Allow-Headers: Authorization, Content-Type, Accept, X-Requested-With
Access-Control-Allow-Credentials: true
```

### 4. Test from Frontend
After deployment, test the login from your frontend:

```javascript
// JavaScript test
fetch('https://fleet.matean.online/api/v1/cors/test', {
  method: 'GET',
  headers: {
    'Content-Type': 'application/json',
  },
  credentials: 'include'
})
.then(response => response.json())
.then(data => console.log('CORS test successful:', data))
.catch(error => console.error('CORS test failed:', error));

// Test actual login
fetch('https://fleet.matean.online/api/v1/auth/login', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  credentials: 'include',
  body: JSON.stringify({
    email: 'your-test-email@example.com',
    password: 'your-test-password'
  })
})
.then(response => response.json())
.then(data => console.log('Login successful:', data))
.catch(error => console.error('Login failed:', error));
```

## Troubleshooting

### If CORS Still Doesn't Work:

1. **Check Rails Logs:**
   ```bash
   # Check if requests are reaching the server
   tail -f log/production.log
   ```

2. **Verify Gem Installation:**
   ```bash
   bundle list | grep rack-cors
   ```

3. **Check Middleware Order:**
   ```bash
   rails runner "puts Rails.application.middleware"
   ```

4. **Browser Developer Tools:**
   - Check Network tab for OPTIONS requests
   - Look for CORS error messages in Console
   - Verify request/response headers

5. **Common Issues:**
   - Cache: Clear browser cache and try again
   - CDN: If using CDN, ensure it's not stripping CORS headers
   - Load Balancer: Check if load balancer is configured to pass through CORS headers

### Additional Headers for Complex Requests:
If your frontend sends complex requests, you might need to add more headers:

```ruby
# In cors.rb, update headers to include:
headers: ['Authorization', 'Content-Type', 'Accept', 'X-Requested-With', 'X-CSRF-Token', 'X-API-Key']
```

## Security Notes

1. **Specific Origins:** The configuration now uses specific origins instead of wildcards for production
2. **Credentials:** `credentials: true` allows cookies and authorization headers
3. **Host Authorization:** Added to prevent host header injection attacks
4. **Max Age:** Preflight requests are cached for 24 hours to improve performance

## Testing Checklist

- [ ] Deploy to production
- [ ] Restart application
- [ ] Test OPTIONS preflight request with curl
- [ ] Test actual POST request with curl
- [ ] Test from frontend browser
- [ ] Check browser developer tools for CORS headers
- [ ] Verify login functionality works end-to-end

## Rollback Plan

If issues occur, you can quickly rollback by reverting the CORS configuration to allow all origins temporarily:

```ruby
# Emergency rollback - config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'
    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end
```

Then redeploy and investigate the specific issue.