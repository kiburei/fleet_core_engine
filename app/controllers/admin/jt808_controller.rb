module Admin
  class Jt808Controller < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_admin

    def index
      # expose the registry keys (terminal ids)
      keys = fetch_registry_keys
      respond_to do |format|
        format.html { render plain: keys.join("\n") }
        format.json { render json: { keys: keys } }
      end
    end

    private

    def ensure_admin
      unless current_user&.admin?
        render plain: "Forbidden", status: :forbidden
      end
    end

    def fetch_registry_keys
      # Access internal map safely
      map = Jt808::Registry.instance_variable_get(:@map) rescue {}
      map.keys
    end
  end
end
