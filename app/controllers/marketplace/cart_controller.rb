class Marketplace::CartController < ApplicationController
  before_action :authenticate_user!
  
  def save
    session[:cart] = params[:cart].to_json
    render json: { status: 'success' }
  end
end
