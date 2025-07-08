class Marketplace::ProductsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_provider_or_admin!, only: %i[ new create edit update destroy ]
  before_action :set_marketplace_product, only: %i[ show edit update destroy ]

  # GET /marketplace/products or /marketplace/products.json
  def index
    @per_page = params[:per_page] || 10
    @marketplace_products = Marketplace::Product.includes(:user)
    
    # Apply search filter
    if params[:search].present?
      search_term = "%#{params[:search].strip}%"
      @marketplace_products = @marketplace_products.where(
        "name LIKE ? OR description LIKE ? OR tags LIKE ?", 
        search_term, search_term, search_term
      )
    end
    
    # Apply category filter
    if params[:category].present?
      @marketplace_products = @marketplace_products.where(category: params[:category])
    end
    
    # Apply sorting
    case params[:sort]
    when 'price_asc'
      @marketplace_products = @marketplace_products.order(:price)
    when 'price_desc'
      @marketplace_products = @marketplace_products.order(price: :desc)
    when 'name_asc'
      @marketplace_products = @marketplace_products.order(:name)
    when 'featured'
      @marketplace_products = @marketplace_products.order(featured: :desc, created_at: :desc)
    else # 'newest' or default
      @marketplace_products = @marketplace_products.order(created_at: :desc)
    end
    
    @marketplace_products = @marketplace_products.page(params[:page]).per(@per_page)
    @marketplace_product = Marketplace::Product.new
  end

  # GET /marketplace/products/1 or /marketplace/products/1.json
  def show
  end

  # GET /marketplace/products/new
  def new
    @marketplace_product = Marketplace::Product.new
  end

  # GET /marketplace/products/1/edit
  def edit
    unless @marketplace_product.can_edit?(current_user)
      redirect_to @marketplace_product, alert: "You are not authorized to edit this product."
    end
  end

  # POST /marketplace/products or /marketplace/products.json
  def create
    @marketplace_product = Marketplace::Product.new(marketplace_product_params)
    @marketplace_product.user = current_user

    respond_to do |format|
      if @marketplace_product.save
        format.html { redirect_to @marketplace_product, notice: "Product was successfully created." }
        format.json { render :show, status: :created, location: @marketplace_product }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @marketplace_product.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /marketplace/products/1 or /marketplace/products/1.json
  def update
    unless @marketplace_product.can_edit?(current_user)
      redirect_to @marketplace_product, alert: "You are not authorized to edit this product."
      return
    end

    respond_to do |format|
      if @marketplace_product.update(marketplace_product_params)
        format.html { redirect_to @marketplace_product, notice: "Product was successfully updated." }
        format.json { render :show, status: :ok, location: @marketplace_product }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @marketplace_product.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /marketplace/products/1 or /marketplace/products/1.json
  def destroy
    unless current_user.admin? || @marketplace_product.can_edit?(current_user)
      redirect_to @marketplace_product, alert: "You are not authorized to delete this product."
      return
    end

    @marketplace_product.destroy!

    respond_to do |format|
      format.html { redirect_to marketplace_products_path, status: :see_other, notice: "Product was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_marketplace_product
      @marketplace_product = Marketplace::Product.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def marketplace_product_params
      params.expect(marketplace_product: [ :name, :description, :price, :category, :target_audience, :active, :featured, :tags, :image ])
    end

    def authorize_provider_or_admin!
      unless current_user.admin? || current_user.service_provider?
        redirect_to marketplace_products_path, alert: "You are not authorized to perform this action."
      end
    end
end
