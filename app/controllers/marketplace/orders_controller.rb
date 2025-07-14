class Marketplace::OrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_order, only: [:show, :update, :destroy]
  before_action :check_permission, only: [:show, :update, :destroy]

  def index
    if current_user.service_provider?
      # Get orders that contain products from this service provider
      @orders = Marketplace::Order.joins(order_items: :product)
                                 .where(marketplace_products: { user: current_user })
                                 .includes(order_items: :product, user: true)
                                 .distinct
                                 .recent
                                 .page(params[:page]).per(10)
    else
      @orders = current_user.orders.includes(order_items: :product).recent.page(params[:page]).per(10)
    end
  end

  def show
  end

  def create
    # Create an order from the cart
    order_creation_service = OrderCreationService.new(current_user, session[:cart])
    @order = order_creation_service.call

    if @order.persisted?
      redirect_to @order, notice: 'Order was successfully created.'
    else
      redirect_to marketplace_products_path, alert: 'Failed to create order.'
    end
  end

  def update
    if @order.update(order_params)
      redirect_to @order, notice: 'Order was successfully updated.'
    else
      redirect_to @order, alert: 'Failed to update order.'
    end
  end

  def destroy
    @order.destroy
    redirect_to marketplace_orders_path, notice: 'Order was successfully destroyed.'
  end

  private

  def set_order
    @order = Marketplace::Order.find(params[:id])
  end

  def check_permission
    # Allow access if user is the customer, admin, or service provider with products in the order
    has_products_in_order = current_user.service_provider? && 
                           @order.order_items.joins(:product).where(marketplace_products: { user: current_user }).exists?
    
    unless @order.user == current_user || current_user.admin? || has_products_in_order
      redirect_to marketplace_orders_path, alert: 'You are not authorized.'
    end
  end

  def order_params
    params.require(:marketplace_order).permit(:status, :payment_status)
  end
end

