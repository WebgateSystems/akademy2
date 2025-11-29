# frozen_string_literal: true

module Api
  module V1
    class ContentsController < ApplicationApiController
      before_action :authorize_access_request!

      def index
        result = Api::V1::Contents::ListContents.call(params:, current_user:)
        default_handler(result)
      end

      def show
        result = Api::V1::Contents::ShowContent.call(params:, current_user:)
        default_handler(result)
      end
    end
  end
end
