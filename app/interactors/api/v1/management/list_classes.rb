# frozen_string_literal: true

module Api
  module V1
    module Management
      class ListClasses < BaseInteractor
        def call
          authorize!
          load_classes
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

        def load_classes
          return context.fail!(message: ['Brak przypisanej szkoły']) unless school

          year = context.params[:year] || school.current_academic_year_value
          classes = SchoolClass.where(school: school, year: year).order(:name)

          context.form = classes
          context.status = :ok
          context.serializer = SchoolClassSerializer
        end
      end
    end
  end
end
