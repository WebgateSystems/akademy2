Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  devise_for :users, controllers: { sessions: 'users/sessions' }

  get    '/admin/sign_in',  to: 'admin/sessions#new',     as: :new_admin_session
  post   '/admin/sign_in',  to: 'admin/sessions#create',  as: :admin_session
  delete '/admin/sign_out', to: 'admin/sessions#destroy', as: :destroy_admin_session

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

  namespace :register do
    get  'profile',       to: 'wizard#profile', as: :profile
    post 'profile',       to: 'wizard#profile_submit'

    get  'verify-phone',  to: 'wizard#verify_phone', as: :verify_phone
    get  'resend-code',   to: 'wizard#resend-code'
    post 'verify-phone',  to: 'wizard#verify_phone_submit'

    get  'set-pin',       to: 'wizard#set_pin', as: :set_pin
    post 'set-pin',       to: 'wizard#set_pin_submit'

    get  'set-pin-confirm', to: 'wizard#set_pin_confirm', as: :set_pin_confirm
    post 'set-pin-confirm', to: 'wizard#set_pin_confirm_submit'

    get  'confirm-email', to: 'wizard#confirm_email', as: :confirm_email
  end

  authenticated :user do
    root 'dashboard#index', as: :authenticated_root
  end

  namespace :api do
    namespace :v1 do
      resource :session, only: [:create], path: 'session'
      resources :schools, only: %i[index show create update destroy]
      resources :headmasters, only: %i[index show create update destroy]
    end
  end

  # API
  # devise_scope :user do
  #   post "/api/v1/auth/register", to: "api/v1/users/registrations#create"
  # end

  root 'home#index'
end
