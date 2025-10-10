class Api::V1::BaseController < ApplicationController
  # Skip Devise authentication for API endpoints
  skip_before_action :authenticate_user!
  
  before_action :authenticate_api_user!
  before_action :set_current_user
  
  skip_before_action :verify_authenticity_token
  
  respond_to :json

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :record_invalid
  rescue_from ArgumentError, with: :argument_error

  private

  def authenticate_api_user!
    token = extract_token_from_header
    return render_unauthorized unless token

    begin
      decoded_token = JsonWebToken.decode(token)
      @current_user = User.find(decoded_token[:user_id])
    rescue JWT::DecodeError, JWT::ExpiredSignature, ActiveRecord::RecordNotFound
      render_unauthorized
    end
  end

  def set_current_user
    # Set current user in ActiveSupport::CurrentAttributes if it exists
    # Current.user = @current_user if defined?(Current)
  end

  def current_user
    @current_user
  end

  def current_driver
    @current_driver ||= current_user&.driver
  end

  def extract_token_from_header
    auth_header = request.headers['Authorization']
    return nil unless auth_header&.start_with?('Bearer ')
    
    auth_header.split(' ').last
  end

  def render_unauthorized(message = 'Unauthorized')
    render json: { error: message }, status: :unauthorized
  end

  def render_success(data = {}, message = 'Success', status = :ok)
    response = { success: true, message: message }
    response[:data] = data unless data.empty?
    render json: response, status: status
  end

  def render_error(message, status = :unprocessable_entity, errors = nil)
    response = { success: false, error: message }
    response[:errors] = errors if errors.present?
    render json: response, status: status
  end

  def record_not_found(exception)
    render_error("Resource not found: #{exception.message}", :not_found)
  end

  def record_invalid(exception)
    render_error("Validation failed", :unprocessable_entity, exception.record.errors)
  end

  def argument_error(exception)
    render_error(exception.message, :bad_request)
  end

  def paginate_collection(collection, per_page: 20)
    page = params[:page]&.to_i || 1
    per_page = [params[:per_page]&.to_i || per_page, 100].min
    
    collection.page(page).per(per_page)
  end

  def pagination_meta(collection)
    {
      current_page: collection.current_page,
      total_pages: collection.total_pages,
      total_count: collection.total_count,
      per_page: collection.limit_value
    }
  end
end