# frozen_string_literal: true

module Api
  module V1
    class StudentsController < ApplicationApiController
      before_action :authorize_access_request!

      def index
        result = Api::V1::Students::ListStudents.call(params:, current_user:)
        default_handler(result)
      end

      def show
        result = Api::V1::Students::ShowStudent.call(params:, current_user:)
        default_handler(result)
      end

      def create
        result = Api::V1::Students::CreateStudent.call(params:, current_user:)
        default_handler(result)
      end

      def update
        result = Api::V1::Students::UpdateStudent.call(params:, current_user:)
        default_handler(result)
      end

      def destroy
        result = Api::V1::Students::DestroyStudent.call(params:, current_user:)
        default_handler(result)
      end

      def resend_invite
        result = Api::V1::Students::ResendInviteStudent.call(params:, current_user:)
        default_handler(result)
      end

      def lock
        result = Api::V1::Students::LockStudent.call(params:, current_user:)
        default_handler(result)
      end
    end
  end
end
