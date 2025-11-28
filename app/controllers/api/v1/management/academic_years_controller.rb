# frozen_string_literal: true

module Api
  module V1
    module Management
      class AcademicYearsController < Api::V1::Management::BaseController
        def index
          result = Api::V1::Management::ListAcademicYears.call(params: params, current_user: current_user)
          default_handler(result)
        end

        def show
          result = Api::V1::Management::ShowAcademicYear.call(params: params, current_user: current_user)
          default_handler(result)
        end

        def create
          result = Api::V1::Management::CreateAcademicYear.call(params: params, current_user: current_user)
          default_handler(result)
        end

        def update
          result = Api::V1::Management::UpdateAcademicYear.call(params: params, current_user: current_user)
          default_handler(result)
        end

        def destroy
          result = Api::V1::Management::DestroyAcademicYear.call(params: params, current_user: current_user)
          default_handler(result)
        end
      end
    end
  end
end
