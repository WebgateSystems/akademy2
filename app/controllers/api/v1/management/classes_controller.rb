# frozen_string_literal: true

module Api
  module V1
    module Management
      class ClassesController < Api::V1::Management::BaseController
        def index
          result = Api::V1::Management::ListClasses.call(params: params, current_user: current_user)
          default_handler(result)
        end

        def show
          result = Api::V1::Management::ShowClass.call(params: params, current_user: current_user)
          default_handler(result)
        end

        def create
          result = Api::V1::Management::CreateClass.call(params: params, current_user: current_user)
          default_handler(result)
        end

        def update
          result = Api::V1::Management::UpdateClass.call(params: params, current_user: current_user)
          default_handler(result)
        end

        def destroy
          result = Api::V1::Management::DestroyClass.call(params: params, current_user: current_user)
          default_handler(result)
        end

        def archive_year
          result = Api::V1::Management::ArchiveYear.call(params: params, current_user: current_user)
          default_handler(result)
        end
      end
    end
  end
end
