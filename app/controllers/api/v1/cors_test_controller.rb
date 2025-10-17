class Api::V1::CorsTestController < ApplicationController
  # Skip CSRF protection for API endpoints
  skip_before_action :verify_authenticity_token
  
  def preflight_check
    # This endpoint specifically handles OPTIONS requests for CORS testing
    head :ok
  end
  
  def test
    render json: {
      message: "CORS is working correctly!",
      timestamp: Time.current,
      origin: request.headers['HTTP_ORIGIN']
    }
  end
end