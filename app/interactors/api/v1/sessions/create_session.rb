module Api
  module V1
    module Sessions
      class CreateSession < BaseInteractor
        def call
          context.strategy = ::Auth::AuthStrategyResolver.resolve(session_params)
          invalid_credentials unless strategy

          context.user = strategy.user
          user_not_exist unless user

          wrong_password unless authenticate

          create_jwt
          success
        end

        private

        def strategy
          context.strategy
        end

        def session_params
          context.params[:user] || {}
        end

        def user
          context.user
        end

        def authenticate
          user.valid_password?(strategy.password)
        end

        def invalid_credentials
          context.fail!(message: ['Missing login fields'])
        end

        def user_not_exist
          context.fail!(message: ['User does not exist'])
        end

        def wrong_password
          context.fail!(message: ['Invalid password or PIN'])
        end

        def create_jwt
          context.access_token = Jwt::TokenService.encode(user_id: user.id)

          # Log login event
          EventLogger.log_login(user:, client: 'api')
        end

        def success
          context.status = :created
          context.form = user
        end
      end
    end
  end
end
