# frozen_string_literal: true

module Api
  module V1
    module Management
      class TeachersController < Api::V1::Management::BaseController
        def index
          result = Api::V1::Management::ListTeachers.call(params:, current_user:)
          default_handler(result)
        end

        def show
          result = Api::V1::Management::ShowTeacher.call(params:, current_user:)
          default_handler(result)
        end

        def create
          result = Api::V1::Management::CreateTeacher.call(params:, current_user:)
          default_handler(result)
        end

        def update
          result = Api::V1::Management::UpdateTeacher.call(params:, current_user:)
          default_handler(result)
        end

        def destroy
          result = Api::V1::Management::DestroyTeacher.call(params:, current_user:)
          default_handler(result)
        end

        def resend_invite
          result = Api::V1::Management::ResendInviteTeacher.call(params:, current_user:)
          default_handler(result)
        end

        def lock
          result = Api::V1::Management::LockTeacher.call(params:, current_user:)
          default_handler(result)
        end

        def approve
          result = Api::V1::Management::ApproveTeacher.call(params:, current_user:)
          default_handler(result)
        end

        def decline
          result = Api::V1::Management::DestroyTeacher.call(params:, current_user:)
          default_handler(result)
        end
      end
    end
  end
end
