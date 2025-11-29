# frozen_string_literal: true

module Api
  module V1
    class SubjectsController < ApplicationApiController
      before_action :authorize_access_request!

      def index
        result = Api::V1::Subjects::ListSubjects.call(params:, current_user:)
        default_handler(result)
      end

      def show
        result = Api::V1::Subjects::ShowSubject.call(params:, current_user:)
        default_handler(result)
      end

      def with_contents
        result = Api::V1::Subjects::ListSubjectsWithContents.call(params:, current_user:)
        default_handler(result)
      end
    end
  end
end
