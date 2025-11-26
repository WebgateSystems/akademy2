module Api
  module V1
    module Register
      class FlowsController < ApplicationApiController
        def create
          result = Api::V1::Register::Flows::Create.call(serializer: FlowSerializer)
          default_handler(result)
        end
      end
    end
  end
end
