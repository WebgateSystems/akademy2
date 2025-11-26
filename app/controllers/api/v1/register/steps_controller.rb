module Api
  module V1
    module Register
      class StepsController < ApplicationApiController
        def profile
          result = Api::V1::Register::Steps::Profile.call(params:, serializer: FlowSerializer)
          default_handler(result)
        end

        def verify_phone
          result = Api::V1::Register::Steps::VerifyPhone.call(params:, serializer: FlowSerializer)
          default_handler(result)
        end

        def set_pin
          result = Api::V1::Register::Steps::SetPin.call(params:, serializer: FlowSerializer)
          default_handler(result)
        end

        def confirm_pin
          result = Api::V1::Register::Steps::ConfirmPin.call(params:, serializer: UserSerializer)
          default_handler(result)
        end
      end
    end
  end
end
