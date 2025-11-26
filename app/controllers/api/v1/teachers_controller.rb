# frozen_string_literal: true

module Api
  module V1
    class TeachersController < ApplicationApiController
      before_action :authorize_access_request!

      def index
        result = Api::V1::Teachers::ListTeachers.call(params:, current_user:)
        default_handler(result)
      end

      def show
        result = Api::V1::Teachers::ShowTeacher.call(params:, current_user:)
        default_handler(result)
      end

      def create
        result = Api::V1::Teachers::CreateTeacher.call(params:, current_user:)
        default_handler(result)
      end

      def update
        result = Api::V1::Teachers::UpdateTeacher.call(params:, current_user:)
        default_handler(result)
      end

      def destroy
        result = Api::V1::Teachers::DestroyTeacher.call(params:, current_user:)
        default_handler(result)
      end

      def resend_invite
        result = Api::V1::Teachers::ResendInviteTeacher.call(params:, current_user:)
        default_handler(result)
      end

      def lock
        result = Api::V1::Teachers::LockTeacher.call(params:, current_user:)
        default_handler(result)
      end
    end
  end
end
