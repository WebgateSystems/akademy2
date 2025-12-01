Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  devise_for :users, controllers: { sessions: 'users/sessions' }

  get    '/admin/sign_in',  to: 'admin/sessions#new',     as: :new_admin_session
  post   '/admin/sign_in',  to: 'admin/sessions#create',  as: :admin_session
  delete '/admin/sign_out', to: 'admin/sessions#destroy', as: :destroy_admin_session

  namespace :admin do
    root to: 'dashboard#index'
    get 'notifications', to: 'notifications#index', as: :notifications
    post 'notifications/mark_as_read', to: 'notifications#mark_as_read', as: :mark_notification_as_read
    post 'subjects/reorder', to: 'resources#reorder_subjects', as: :reorder_subjects
    post 'learning_modules/:id/reorder_contents', to: 'resources#reorder_learning_module_contents',
                                                  as: :reorder_learning_module_contents
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

    # Teacher registration
    get 'teacher', to: 'wizard#teacher', as: :teacher
  end

  namespace :management do
    root to: 'dashboard#index'
    get 'qr_code.svg', to: 'qr_codes#svg', as: :qr_code_svg
    get 'qr_code.png', to: 'qr_codes#png', as: :qr_code_png
    get 'administration', to: 'administrations#index', as: :administration
    get 'teachers', to: 'teachers#index', as: :teachers
    get 'students', to: 'students#index', as: :students
    get 'parents', to: 'parents#index', as: :parents
    get 'notifications', to: 'notifications#index', as: :notifications
    get 'classes', to: 'classes#index', as: :classes
    get 'years', to: 'years#index', as: :years
  end

  namespace :api do
    namespace :v1 do
      namespace :management do
        resources :administrations, only: %i[index show create update destroy] do
          member do
            post :resend_invite
            post :lock
          end
        end
        resources :teachers, only: %i[index show create update destroy] do
          member do
            post :resend_invite
            post :lock
            post :approve
            post :decline
          end
        end
        resources :students, only: %i[index show create update destroy] do
          member do
            post :resend_invite
            post :lock
            post :approve
            delete :decline
          end
        end
        resources :parents, only: %i[index show create update destroy] do
          member do
            post :resend_invite
            post :lock
          end
          collection do
            get :search_students
          end
        end
        resources :notifications, only: [] do
          collection do
            post :mark_as_read
          end
        end
        resources :classes, only: %i[index show create update destroy] do
          collection do
            post :archive_year
          end
        end
        resources :academic_years, only: %i[index show create update destroy]
      end
    end
  end

  authenticated :user do
    root 'dashboard#index', as: :authenticated_root
    get '/dashboard', to: 'dashboard#index', as: :dashboard
  end

  namespace :api do
    namespace :v1 do
      resource :session, only: :create
      resources :schools, only: %i[index show create update destroy]
      resources :headmasters, only: %i[index show create update destroy] do
        member do
          post :resend_invite
          post :lock
        end
      end
      resources :teachers, only: %i[index show create update destroy] do
        member do
          post :resend_invite
          post :lock
        end
      end
      resources :students, only: %i[index show create update destroy] do
        member do
          post :resend_invite
          post :lock
        end
      end
      resources :events, only: [:index]
      resources :subjects, only: %i[index show] do
        collection do
          get :with_contents
        end
      end
      resources :units, only: %i[index show]
      resources :learning_modules, only: %i[index show]
      resources :contents, only: %i[index show]

      namespace :register do
        get 'flow', to: 'flows#create'

        post 'profile',        to: 'steps#profile'
        post 'verify_phone',   to: 'steps#verify_phone'
        post 'set_pin',        to: 'steps#set_pin'
        post 'confirm_pin',    to: 'steps#confirm_pin'
      end
    end
  end

  get '/home', to: 'home#index', as: :public_home
  root 'home#index'
end
