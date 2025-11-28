# frozen_string_literal: true

module Api
  module V1
    module Management
      class ShowClass < BaseInteractor
        def call
          authorize!
          find_class
        end

        private

        def authorize!
          policy = SchoolManagementPolicy.new(current_user, :school_management)
          return if policy.access?

          context.message = ['Brak uprawnień']
          context.fail!
        end

        def current_user
          context.current_user
        end

        def school
          @school ||= begin
            user_school = current_user.school
            return user_school if user_school

            user_role = current_user.user_roles
                                    .joins(:role)
                                    .where(roles: { key: %w[principal school_manager] })
                                    .first
            user_role&.school
          end
        end

        def find_class
          return context.fail!(message: ['Brak przypisanej szkoły']) unless school

          class_id = get_param_value(:id)
          school_class = SchoolClass.find_by(id: class_id, school: school)

          unless school_class
            context.message = ['Klasa nie została znaleziona']
            context.status = :not_found
            context.fail!
            return
          end

          context.form = school_class
          context.status = :ok
          context.serializer = SchoolClassSerializer
        end

        def get_param_value(*keys)
          current_params = context.params
          keys.each do |key|
            current_params = if current_params.is_a?(ActionController::Parameters)
                               current_params[key]
                             elsif current_params.is_a?(Hash)
                               current_params[key.to_s] || current_params[key.to_sym]
                             end
            return nil if current_params.nil?
          end
          current_params
        end
      end
    end
  end
end
