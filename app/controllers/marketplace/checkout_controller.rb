class Marketplace::CheckoutController < ApplicationController
  before_action :authenticate_user!
  before_action :check_cart_not_empty, only: [:new, :create]

  def new
    @cart_items = get_cart_items
    @total = calculate_total(@cart_items)
    @order = Marketplace::Order.new
  end

  def create
    @cart_items = get_cart_items
    @total = calculate_total(@cart_items)
    
    ActiveRecord::Base.transaction do
      @order = create_order(@cart_items, @total)
      
      if @order.persisted?
        # Process payment
        payment_result = process_payment(@order, checkout_params[:payment_method])
        
        if payment_result[:success]
          @order.update!(payment_status: :paid, status: :processing)
          clear_cart
          redirect_to marketplace_order_path(@order), notice: 'Order placed successfully!'
        else
          @order.update!(payment_status: :unpaid, status: :cancelled)
          redirect_to new_marketplace_checkout_path, alert: payment_result[:message]
        end
      else
        redirect_to new_marketplace_checkout_path, alert: 'Failed to create order.'
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    redirect_to new_marketplace_checkout_path, alert: "Order failed: #{e.message}"
  end

  private

  def get_cart_items
    cart_data = JSON.parse(session[:cart] || '[]')
    cart_data.map do |item|
      product = Marketplace::Product.find(item['id'])
      {
        product: product,
        quantity: item['quantity'],
        unit_price: product.price,
        total_price: product.price * item['quantity']
      }
    end
  rescue JSON::ParserError
    []
  end

  def calculate_total(cart_items)
    cart_items.sum { |item| item[:total_price] }
  end

  def create_order(cart_items, total)
    order = Marketplace::Order.new(
      user: current_user,
      total_amount: total,
      status: :pending,
      payment_status: :unpaid
    )

    if order.save
      cart_items.each do |item|
        order.order_items.create!(
          product: item[:product],
          quantity: item[:quantity],
          unit_price: item[:unit_price],
          total_price: item[:total_price]
        )
      end
    end

    order
  end

  def process_payment(order, payment_method)
    # This is a placeholder for payment processing
    # In a real application, you would integrate with payment gateways
    
    payment = Marketplace::Payment.new(
      order: order,
      user: current_user,
      amount: order.total_amount,
      payment_method: payment_method,
      status: :pending
    )

    if payment.save
      # Simulate payment processing
      case payment_method
      when 'credit_card', 'debit_card'
        simulate_card_payment(payment)
      when 'mobile_money'
        simulate_mobile_money_payment(payment)
      when 'bank_transfer'
        simulate_bank_transfer_payment(payment)
      else
        { success: false, message: 'Invalid payment method' }
      end
    else
      { success: false, message: 'Failed to initialize payment' }
    end
  end

  def simulate_card_payment(payment)
    # Card payment processing
    if rand(1..10) > 2  # 80% success rate
      payment.update!(status: :completed)
      { success: true, message: 'Payment processed successfully' }
    else
      payment.update!(status: :failed)
      { success: false, message: 'Card payment failed. Please try again.' }
    end
  end

  def simulate_mobile_money_payment(payment)
    # Mobile money payment processing
    if rand(1..10) > 3  # 70% success rate
      payment.update!(status: :completed)
      { success: true, message: 'Mobile money payment processed successfully' }
    else
      payment.update!(status: :failed)
      { success: false, message: 'Mobile money payment failed. Please try again.' }
    end
  end

  def simulate_bank_transfer_payment(payment)
    # Bank transfers typically require manual verification
    payment.update!(status: :processing)
    { success: true, message: 'Bank transfer initiated. Payment will be processed within 1-2 business days.' }
  end

  def clear_cart
    session[:cart] = nil
  end

  def check_cart_not_empty
    cart_items = get_cart_items
    if cart_items.empty?
      redirect_to marketplace_products_path, alert: 'Your cart is empty.'
    end
  end

  def checkout_params
    params.require(:checkout).permit(:payment_method, :billing_address, :shipping_address)
  end
end
