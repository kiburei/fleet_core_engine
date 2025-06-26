Rails.application.routes.draw do
  devise_for :users
  root "dashboard#index"
  resources :trips do
    resource :manifest, only: [ :new, :create, :edit, :update, :show ]
  end
  resources :drivers do
    resources :documents, only: [ :index, :new, :create, :show ]
    resources :incidents, only: [ :index, :new, :create, :show ]
  end
  resources :vehicles do
    resources :documents, only: [ :index, :new, :create, :show ]
    resources :maintenances, only: [ :index, :new, :create, :show ]
    resources :incidents, only: [ :index, :new, :create, :show ]
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

  namespace :admin do
    resources :users, only: [ :index, :edit, :show, :update ]
  end

  # Marketplace routes
  get "marketplace", to: "marketplace/products#index"
  namespace :marketplace do
    resources :products
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
