class Api::V1::AuthController < Api::V1::BaseController
  skip_before_action :authenticate_api_user!, only: [:login, :register]

  def login
    # Handle both nested auth params and flat params
    email = params[:email] || params.dig(:auth, :email)
    password = params[:password] || params.dig(:auth, :password)
    
    return render_error('Email and password are required', :bad_request) if email.blank? || password.blank?
    
    user = User.find_by(email: email)
    
    if user&.valid_password?(password)
      # Check if user is a driver
      driver = user.driver
      if driver.nil?
        return render_error('User is not registered as a driver', :forbidden)
      end

      token = JsonWebToken.encode(user_id: user.id, driver_id: driver.id)
      
      render_success({
        token: token,
        user: user_data(user),
        driver: driver_data(driver)
      }, 'Login successful')
    else
      render_error('Invalid email or password', :unauthorized)
    end
  end

  def register
    user = User.new(user_params)
    
    if user.save
      token = JsonWebToken.encode(user_id: user.id)
      
      render_success({
        token: token,
        user: user_data(user)
      }, 'Registration successful', :created)
    else
      render_error('Registration failed', :unprocessable_entity, user.errors)
    end
  end

  def profile
    render_success({
      user: user_data(current_user),
      driver: current_driver ? driver_data(current_driver) : nil
    })
  end

  def update_profile
    if current_user.update(user_update_params)
      render_success({
        user: user_data(current_user),
        driver: current_driver ? driver_data(current_driver) : nil
      }, 'Profile updated successfully')
    else
      render_error('Update failed', :unprocessable_entity, current_user.errors)
    end
  end

  def update_driver_profile
    return render_error('Driver profile not found', :not_found) unless current_driver

    if current_driver.update(driver_update_params)
      render_success({
        driver: driver_data(current_driver)
      }, 'Driver profile updated successfully')
    else
      render_error('Update failed', :unprocessable_entity, current_driver.errors)
    end
  end

  def update_fcm_token
    return render_error('Driver profile not found', :not_found) unless current_driver

    if current_driver.update(fcm_token: params[:fcm_token])
      render_success({}, 'FCM token updated successfully')
    else
      render_error('Failed to update FCM token', :unprocessable_entity, current_driver.errors)
    end
  end

  def logout
    # In JWT, we don't need to do anything server-side for logout
    # The client should just discard the token
    render_success({}, 'Logged out successfully')
  end

  private

  def user_params
    params.permit(:email, :password, :password_confirmation, :first_name, :last_name)
  end

  def user_update_params
    params.permit(:first_name, :last_name, :phone)
  end

  def driver_update_params
    params.permit(
      :first_name, :middle_name, :last_name, :phone_number,
      :max_delivery_distance_km, :profile_picture
    )
  end

  def user_data(user)
    {
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      phone: user.phone,
      created_at: user.created_at.iso8601
    }
  end

  def driver_data(driver)
    {
      id: driver.id,
      first_name: driver.first_name,
      middle_name: driver.middle_name,
      last_name: driver.last_name,
      full_name: driver.full_name,
      phone_number: driver.phone_number,
      delivery_rating: driver.delivery_rating.to_f,
      total_deliveries: driver.total_deliveries,
      is_online: driver.is_online,
      is_available_for_delivery: driver.is_available_for_delivery,
      max_delivery_distance_km: driver.max_delivery_distance_km,
      current_location: driver.current_location,
      last_location_update: driver.last_location_update&.iso8601,
      fleet_provider: {
        id: driver.fleet_provider.id,
        name: driver.fleet_provider.name
      }
    }
  end
end