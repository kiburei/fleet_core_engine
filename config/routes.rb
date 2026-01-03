Rails.application.routes.draw do
  devise_for :users
  root "dashboard#index"
  resources :devices
  resources :devices do
    member do
      post :ping
    end
  end
  resources :trips do
    resource :manifest, only: [ :new, :create, :edit, :update, :show ]
  end
  resources :drivers do
    member do
      post :create_user_account
      patch :reset_password
      patch :deactivate_user
      patch :reactivate_user
    end
    resources :documents, only: [ :index, :new, :create, :show ]
    resources :incidents, only: [ :index, :new, :create, :show ]
    resources :trips, only: [ :index, :show ]
  end
  resources :vehicles do
    resources :documents, only: [ :index, :new, :create, :show ]
    resources :maintenances, only: [ :index, :new, :create, :show ]
    resources :incidents, only: [ :index, :new, :create, :show ]
    resources :trips, only: [ :index, :show ]
    resources :devices, only: [ :new ]
  end
  resources :vehicle_models
  resources :fleet_providers do
    resources :vehicles, only: [ :index, :show ]
    resources :drivers, only: [ :index, :show ]
    resources :documents, only: [ :index, :new, :create, :show ]
    resources :trips, only: [ :index, :show, :new, :create ]
    resources :incidents, only: [ :index, :new, :create, :show ]
  end
  resources :maintenances do
    resources :documents, only: [ :index, :new, :create, :show ]
  end
  resources :incidents do
    resources :documents, only: [ :index, :new, :create, :show ]
  end

  # Customer Management & Onboarding
  resources :customers do
    member do
      patch :activate
      patch :suspend
      get :onboarding_status
    end
    collection do
      post :bulk_actions
      get :analytics
      get :register, to: "customers#new_registration"
      post :register, to: "customers#create_registration"
      get :onboarding_complete
    end
  end

  # Delivery Services
  resources :delivery_requests do
    member do
      patch :assign_driver
      patch :cancel_delivery
      patch :auto_dispatch
      get :assign_driver
    end
    collection do
      post :bulk_actions
      get :analytics
    end
  end

  namespace :admin do
    root "dashboard#index"
    resources :users, only: [ :index, :edit, :show, :update ]

    resources :drivers do
      member do
        patch :toggle_status
      end
    end

    resources :customers do
      member do
        patch :activate
        patch :suspend
        patch :deactivate
        get :delivery_history
      end
      collection do
        post :bulk_actions
        get :analytics
        get :export
      end
    end

    resources :delivery_requests do
      member do
        patch :assign_driver
        patch :cancel_delivery
        patch :auto_dispatch
        get :assign_driver
      end
      collection do
        post :bulk_actions
        get :analytics
      end
    end
  end

  # Marketplace routes
  get "marketplace", to: "marketplace/products#index"
  namespace :marketplace do
    resources :products
  end

  post "marketplace/cart/save", to: "marketplace/cart#save"
  get "marketplace/checkout/new", to: "marketplace/checkout#new"
  post "marketplace/checkout", to: "marketplace/checkout#create"

  namespace :marketplace do
    resources :orders
  end

  # API routes for mobile app
  namespace :api do
    namespace :v1 do
      # CORS testing endpoints
      options "cors/test", to: "cors_test#preflight_check"
      get "cors/test", to: "cors_test#test"

      # Authentication
      post "auth/login", to: "auth#login"
      post "auth/register", to: "auth#register"
      post "auth/logout", to: "auth#logout"
      post "auth/change_password", to: "auth#change_password"
      get "auth/profile", to: "auth#profile"
      patch "auth/profile", to: "auth#update_profile"
      patch "auth/driver_profile", to: "auth#update_driver_profile"
      patch "auth/fcm_token", to: "auth#update_fcm_token"

      # Location services
      resources :locations, only: [] do
        collection do
          get "search"                      # Search places/addresses
          post "geocode"                    # Convert address to coordinates
          post "reverse_geocode"            # Convert coordinates to address
          post "validate_coordinates"       # Validate and geocode multiple addresses
        end
      end

      # Delivery requests
      resources :delivery_requests, only: [ :index, :show ] do
        collection do
          get "available"                    # Get available deliveries
          get "earnings_summary"            # Get driver earnings summary
          patch "update_location"           # Update driver location
          get "driver_status"               # Get driver status
          patch "go_online"                 # Go online
          patch "go_offline"                # Go offline
          patch "toggle_availability"       # Toggle availability
        end

        member do
          patch "accept"                    # Accept delivery
          patch "decline"                   # Decline delivery
          patch "pickup"                    # Mark as picked up
          patch "mark_in_transit"           # Mark as in transit
          patch "deliver"                   # Mark as delivered
          patch "cancel"                    # Cancel delivery
        end
      end

      # Notifications
      resources :notifications, only: [ :index, :show, :update ] do
        member do
          patch "mark_read"
        end
        collection do
          patch "mark_all_read"
        end
      end
    end
  end

  namespace :rui do
    get "about", to: "pages#about"
    get "pricing", to: "pages#pricing"
    get "dashboard", to: "pages#dashboard"
    get "projects", to: "pages#projects"
    get "project", to: "pages#project"
    get "messages", to: "pages#messages"
    get "message", to: "pages#message"
    get "assignments", to: "pages#assignments"
    get "calendar", to: "pages#calendar"
    get "people", to: "pages#people"
    get "profile", to: "pages#profile"
    get "activity", to: "pages#activity"
    get "settings", to: "pages#settings"
    get "notifications", to: "pages#notifications"
    get "billing", to: "pages#billing"
    get "team", to: "pages#team"
    get "integrations", to: "pages#integrations"
  end

  if Rails.env.development?
    # Visit the start page for Rails UI any time at /railsui/start
    mount Railsui::Engine, at: "/railsui"
  end

  # Inherits from Railsui::PageController#index
  # To override, add your own page#index view or change to a new root
  # root action: :index, controller: "railsui/default"

  # Add routes for railsui stylesheets
  get "/stylesheets/railsui/theme", to: "assets#railsui_theme"
  get "/stylesheets/railsui/actiontext", to: "assets#railsui_actiontext"
  get "/stylesheets/railsui/buttons", to: "assets#railsui_buttons"
  get "/stylesheets/railsui/headings", to: "assets#railsui_headings"
  get "/stylesheets/railsui/forms", to: "assets#railsui_forms"
  get "/stylesheets/railsui/navigation", to: "assets#railsui_navigation"
  get "/service-worker.js", to: "assets#service_worker"

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
