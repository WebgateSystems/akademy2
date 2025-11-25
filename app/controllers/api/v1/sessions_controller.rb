module Api
  module V1
    class SessionsController < ApplicationApiController
      before_action :authorize_access_request!, except: %i[create]

      def create
        result = Api::V1::Sessions::CreateSession.call(params:, serializer: UserSerializer)
        default_handler(result)
      end
    end
  end
end
