# frozen_string_literal: true

module Api
  module V1
    module Management
      class DestroyAcademicYear < BaseInteractor
        def call
          authorize!
          find_academic_year
          destroy_academic_year
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

        def find_academic_year
          return context.fail!(message: ['Brak przypisanej szkoły']) unless school

          year_id = get_param_value(:id)
          context.academic_year = AcademicYear.find_by(id: year_id, school: school)

          return if context.academic_year

          context.message = ['Rok akademicki nie został znaleziony']
          context.status = :not_found
          context.fail!
        end

        def destroy_academic_year
          # Check if year has any classes
          classes_count = SchoolClass.where(school: school, year: context.academic_year.year).count
          if classes_count.positive?
            context.message = ['Nie można usunąć roku akademickiego, ponieważ zawiera klasy']
            context.status = :unprocessable_entity
            context.fail!
            return
          end

          # Destroy without triggering dependent: :restrict_with_error
          # since school_classes are linked by year (string), not foreign key
          if context.academic_year.delete
            context.status = :no_content
          else
            context.message = ['Nie można usunąć roku akademickiego']
            context.fail!
          end
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
