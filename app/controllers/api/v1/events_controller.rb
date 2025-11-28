# frozen_string_literal: true

module Api
  module V1
    class EventsController < AuthentificateController
      def index
        result = Api::V1::Events::ListEvents.call(params:, current_user:)
        default_handler(result)
      end
    end
  end
end
