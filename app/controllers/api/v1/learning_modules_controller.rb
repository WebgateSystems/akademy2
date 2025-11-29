# frozen_string_literal: true

module Api
  module V1
    class LearningModulesController < ApplicationApiController
      before_action :authorize_access_request!

      def index
        result = Api::V1::LearningModules::ListLearningModules.call(params:, current_user:)
        default_handler(result)
      end

      def show
        result = Api::V1::LearningModules::ShowLearningModule.call(params:, current_user:)
        default_handler(result)
      end
    end
  end
end
