# frozen_string_literal: true

module Api
  module V1
    module Management
      class ListAcademicYears < BaseInteractor
        def call
          authorize!
          load_academic_years
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

        def load_academic_years
          return context.fail!(message: ['Brak przypisanej szkoły']) unless school

          academic_years = AcademicYear.where(school: school).ordered

          context.form = academic_years
          context.status = :ok
          context.serializer = AcademicYearSerializer
        end
      end
    end
  end
end
