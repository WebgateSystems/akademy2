# frozen_string_literal: true

module Api
  module V1
    module Management
      class StudentsController < Api::V1::Management::BaseController
        def index
          result = Api::V1::Management::ListStudents.call(params:, current_user:)
          default_handler(result)
        end

        def show
          result = Api::V1::Management::ShowStudent.call(params:, current_user:)
          default_handler(result)
        end

        def create
          result = Api::V1::Management::CreateStudent.call(params:, current_user:)
          default_handler(result)
        end

        def update
          result = Api::V1::Management::UpdateStudent.call(params:, current_user:)
          default_handler(result)
        end

        def destroy
          result = Api::V1::Management::DestroyStudent.call(params:, current_user:) # Decline means destroy
          default_handler(result)
        end

        def resend_invite
          result = Api::V1::Management::ResendInviteStudent.call(params:, current_user:)
          default_handler(result)
        end

        def lock
          result = Api::V1::Management::LockStudent.call(params:, current_user:)
          default_handler(result)
        end

        def approve
          result = Api::V1::Management::ApproveStudent.call(params:, current_user:)
          default_handler(result)
        end

        def decline
          result = Api::V1::Management::DestroyStudent.call(params:, current_user:) # Decline means destroy
          default_handler(result)
        end
      end
    end
  end
end
