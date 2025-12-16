module Api
  module V1
    module Register
      module Flows
        class Create < BaseInteractor
          AVAILABLE_ROLE_KEY = %w[student teacher].freeze

          def call
            add_role_to_flow

            context.form = current_form
            context.status = :created
          end

          private

          def add_role_to_flow
            data = current_form.data || {}
            data[:role_key] = check_available_role_key || :student
            data[:class_token] = context.params[:class_token] if class_token?
            data[:join_token] = context.params[:class_token] if join_token?

            current_form.update(data:)
          end

          def check_available_role_key
            AVAILABLE_ROLE_KEY.include?(context.params[:role_key]) ? context.params[:role_key] : nil
          end

          def current_form
            @current_form ||= RegistrationFlow.create!
          end

          def class_token?
            context.params[:class_token].present?
          end

          def join_token?
            context.params[:join_token].present?
          end
        end
      end
    end
  end
end
