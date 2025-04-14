class FleetProvidersController < ApplicationController
  before_action :set_fleet_provider, only: %i[ show edit update destroy ]

  # GET /fleet_providers or /fleet_providers.json
  def index
    @fleet_providers = FleetProvider.all
  end

  # GET /fleet_providers/1 or /fleet_providers/1.json
  def show
  end

  # GET /fleet_providers/new
  def new
    @fleet_provider = FleetProvider.new
  end

  # GET /fleet_providers/1/edit
  def edit
  end

  # POST /fleet_providers or /fleet_providers.json
  def create
    @fleet_provider = FleetProvider.new(fleet_provider_params)

    respond_to do |format|
      if @fleet_provider.save
        format.html { redirect_to @fleet_provider, notice: "Fleet provider was successfully created." }
        format.json { render :show, status: :created, location: @fleet_provider }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @fleet_provider.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /fleet_providers/1 or /fleet_providers/1.json
  def update
    respond_to do |format|
      if @fleet_provider.update(fleet_provider_params)
        format.html { redirect_to @fleet_provider, notice: "Fleet provider was successfully updated." }
        format.json { render :show, status: :ok, location: @fleet_provider }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @fleet_provider.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /fleet_providers/1 or /fleet_providers/1.json
  def destroy
    @fleet_provider.destroy!

    respond_to do |format|
      format.html { redirect_to fleet_providers_path, status: :see_other, notice: "Fleet provider was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_fleet_provider
      @fleet_provider = FleetProvider.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def fleet_provider_params
      params.expect(fleet_provider: [ :name, :registration_number, :physical_address, :phone_number, :email, :license_status, :license_expiry_date ])
    end
end
