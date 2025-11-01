Rails.application.routes.draw do
  namespace :admin do
    root to: 'dashboard#index'
    get ':resource', to: 'resources#index', as: :resource_collection
    get ':resource/new', to: 'resources#new', as: :new_resource
    post ':resource', to: 'resources#create', as: :create_resource
    get ':resource/:id', to: 'resources#show', as: :resource
    get ':resource/:id/edit', to: 'resources#edit', as: :edit_resource
    patch ':resource/:id', to: 'resources#update', as: :update_resource
    delete ':resource/:id', to: 'resources#destroy', as: :destroy_resource
  end
  devise_for :users, skip: [ :registrations ]
  devise_scope :user do
    post "/api/v1/auth/register", to: "api/v1/users/registrations#create"
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"
end
