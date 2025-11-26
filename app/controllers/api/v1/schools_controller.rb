module Api
  module V1
    class SchoolsController < ApplicationApiController
      before_action :authorize_access_request!

      def index
        result = Api::V1::Schools::ListSchools.call(params:, current_user:)
        default_handler(result)
      end

      def show
        result = Api::V1::Schools::ShowSchool.call(params:, current_user:)
        default_handler(result)
      end

      def create
        result = Api::V1::Schools::CreateSchool.call(params:, current_user:)
        default_handler(result)
      end

      def update
        result = Api::V1::Schools::UpdateSchool.call(params:, current_user:)
        default_handler(result)
      end

      def destroy
        result = Api::V1::Schools::DestroySchool.call(params:, current_user:)
        default_handler(result)
      end
    end
  end
end
