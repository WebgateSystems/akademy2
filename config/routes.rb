Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  devise_for :users, controllers: { sessions: 'users/sessions' }

  # Pretty login URLs (aliases for /users/sign_in?role=xxx)
  devise_scope :user do
    get  '/login/student',        to: 'users/sessions#new', defaults: { role: 'student' }, as: :student_login
    post '/login/student',        to: 'users/sessions#create', defaults: { role: 'student' }
    get  '/login/teacher',        to: 'users/sessions#new', defaults: { role: 'teacher' }, as: :teacher_login
    post '/login/teacher',        to: 'users/sessions#create', defaults: { role: 'teacher' }
    get  '/login/administration', to: 'users/sessions#new', defaults: { role: 'administration' },
                                  as: :administration_login
    post '/login/administration', to: 'users/sessions#create', defaults: { role: 'administration' }
  end

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

  # Teacher dashboard routes - accessible but require authentication (handled by controller)
  get '/dashboard', to: 'dashboard#index', as: :dashboard
  get '/dashboard/students', to: 'dashboard#students', as: :dashboard_students
  get '/dashboard/students/:id', to: 'dashboard#show_student', as: :dashboard_student
  get '/dashboard/notifications', to: 'dashboard#notifications', as: :dashboard_notifications
  post '/dashboard/notifications/mark_as_read', to: 'dashboard#mark_notifications_as_read',
                                                as: :mark_dashboard_notifications_as_read
  get '/dashboard/quiz_results/:subject_id', to: 'dashboard#quiz_results', as: :dashboard_quiz_results
  get '/dashboard/pupil_videos', to: 'dashboard#pupil_videos', as: :dashboard_pupil_videos
  get '/dashboard/class_qr.svg', to: 'dashboard#class_qr_svg', as: :dashboard_class_qr_svg
  get '/dashboard/class_qr.png', to: 'dashboard#class_qr_png', as: :dashboard_class_qr_png

  namespace :api do
    namespace :v1 do
      namespace :teacher do
        get 'dashboard', to: 'dashboard#index'
        get 'dashboard/class/:id', to: 'dashboard#show_class', as: :dashboard_class
        post 'school_enrollments/join', to: 'school_enrollments#join'
        get 'school_enrollments/pending', to: 'school_enrollments#pending'
        delete 'school_enrollments/:id/cancel', to: 'school_enrollments#cancel', as: :cancel_teacher_enrollment

        # Video moderation
        resources :videos, only: %i[index show update destroy] do
          member do
            put :approve
            put :reject
          end
        end
      end

      namespace :student do
        post 'enrollments/join', to: 'enrollments#join'
        get 'enrollments/pending', to: 'enrollments#pending'
        delete 'enrollments/:id/cancel', to: 'enrollments#cancel', as: :cancel_enrollment

        # Student learning API
        get 'dashboard', to: 'dashboard#index'
        get 'subjects/:id', to: 'dashboard#show_subject', as: :subject
        get 'learning_modules/:id', to: 'dashboard#show_module', as: :learning_module
        resources :quiz_results, only: %i[index create]
        resources :events, only: [:create] do
          collection do
            post :batch
          end
        end

        # School videos
        resources :videos, only: %i[index show create update destroy] do
          collection do
            get :my, action: :my_videos
            get :subjects
          end
          member do
            post :like, action: :toggle_like
          end
        end
      end

      resource :session, only: :create

      # User registration via invite token
      namespace :users do
        post 'registrations', to: 'registrations#create'
      end

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

  # Student dashboard - requires student login
  get '/home', to: 'student_dashboard#index', as: :public_home
  get '/home/subjects/:id', to: 'student_dashboard#subject', as: :student_subject
  get '/home/modules/:id', to: 'student_dashboard#learning_module', as: :student_module
  get '/home/modules/:id/quiz', to: 'student_dashboard#quiz', as: :student_quiz
  post '/home/modules/:id/quiz', to: 'student_dashboard#submit_quiz', as: :submit_student_quiz
  get '/home/modules/:id/result', to: 'student_dashboard#result', as: :student_result

  # Student notifications
  get '/home/notifications', to: 'student_dashboard#notifications', as: :student_notifications
  post '/home/notifications/mark_as_read', to: 'student_dashboard#mark_notifications_as_read',
                                           as: :mark_student_notifications_as_read

  # School videos - student views
  get '/home/videos', to: 'student_dashboard#school_videos', as: :student_videos
  get '/home/videos/new', to: 'student_dashboard#new_video', as: :new_student_video
  post '/home/videos', to: 'student_dashboard#create_video'
  delete '/home/videos/:id', to: 'student_dashboard#destroy_video', as: :destroy_student_video
  get '/home/videos/waiting', to: 'student_dashboard#video_waiting', as: :student_video_waiting

  # Content likes (for learning materials)
  post '/home/contents/:id/like', to: 'student_dashboard#toggle_content_like', as: :toggle_content_like

  # Student account
  get '/home/account', to: 'student_dashboard#account', as: :student_account
  patch '/home/account', to: 'student_dashboard#update_account'
  get '/home/account/settings', to: 'student_dashboard#settings', as: :student_settings
  patch '/home/account/settings', to: 'student_dashboard#update_settings'
  delete '/home/account', to: 'student_dashboard#destroy_account', as: :destroy_student_account

  # Join class via token link (for students)
  get '/join/class/:token', to: 'student_dashboard#join_class', as: :join_class

  # Join school via token link (for teachers)
  get '/join/school/:token', to: 'teacher_registration#join_school', as: :join_school

  # Role selection page
  get '/enter', to: 'enter#index', as: :enter

  get 'health', to: 'home#spinup_status'
  get 'version', to: 'home#version'

  # Landing page
  root 'home#index'
end
