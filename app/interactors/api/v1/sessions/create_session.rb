module Api
  module V1
    module Sessions
      class CreateSession < BaseInteractor
        def call
          user_not_exist unless current_user
          wrong_password unless authenticate

          generate_access_token
          setup_varialbes
        end

        private

        def setup_varialbes
          context.form = current_user
          context.status = :created
        end

        def user_not_exist
          context.message = [I18n.t('session.errors.email')]
          context.fail!
        end

        def current_user
          @current_user ||= User.find_by(email: context.params[:user][:email].downcase)
        end

        def authenticate
          current_user.valid_password?(context.params[:user][:password])
        end

        def wrong_password
          context.message = [I18n.t('session.errors.password')]
          context.fail!
        end

        def generate_access_token
          context.access_token = ::Jwt::TokenService.encode({ user_id: current_user.id })
        end
      end
    end
  end
end
