# frozen_string_literal: true

module Api
  module V1
    class EventsController < ApplicationApiController
      before_action :authorize_access_request!

      def index
        result = Api::V1::Events::ListEvents.call(params:, current_user:)
        default_handler(result)
      end
    end
  end
end
