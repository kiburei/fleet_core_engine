class Marketplace::ProductsController < ApplicationController
  # before_action :authenticate_user!
  # before_action :authorize_admin!
  before_action :set_marketplace_product, only: %i[ show edit update destroy ]

  # GET /marketplace/products or /marketplace/products.json
  def index
    @marketplace_products = Marketplace::Product.all
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
  end

  # POST /marketplace/products or /marketplace/products.json
  def create
    @marketplace_product = Marketplace::Product.new(marketplace_product_params)

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
end
