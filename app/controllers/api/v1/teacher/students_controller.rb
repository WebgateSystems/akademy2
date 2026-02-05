# frozen_string_literal: true

module Api
  module V1
    module Teacher
      class StudentsController < ApplicationApiController
        before_action :authorize_access_request!
        before_action :require_teacher!

        # POST /api/v1/teacher/students
        def create
          result = Api::V1::Teacher::CreateStudent.call(current_user:, params:)
          default_handler(result)
        end

        # PATCH /api/v1/teacher/students/:id
        def update
          result = Api::V1::Teacher::UpdateStudent.call(current_user:, params:)
          default_handler(result)
        end

        # GET /api/v1/teacher/students/:id
        def show
          result = Api::V1::Teacher::ShowStudent.call(current_user:, params:)
          default_handler(result)
        end

        private

        def require_teacher!
          return if current_user.teacher?

          render json: { success: false, error: 'Unauthorized - teacher access required' }, status: :forbidden
        end
      end
    end
  end
end
