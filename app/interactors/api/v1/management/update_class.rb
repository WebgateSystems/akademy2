# frozen_string_literal: true

module Api
  module V1
    module Management
      # rubocop:disable Metrics/ClassLength
      class UpdateClass < BaseInteractor
        def call
          authorize!
          find_class
          update_class
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
          context.school_class = SchoolClass.find_by(id: class_id, school: school)

          return if context.school_class

          context.message = ['Klasa nie została znaleziona']
          context.status = :not_found
          context.fail!
        end

        def update_class
          update_params = class_params.to_h
          teacher_id = update_params.delete(:teacher_id)
          teaching_staff_ids = update_params.delete(:teaching_staff_ids)

          return unless context.school_class.update(update_params)

          update_assignments_if_present(teacher_id, teaching_staff_ids)
          context.form = context.school_class
          context.status = :ok
          context.serializer = SchoolClassSerializer
        end

        def update_assignments_if_present(teacher_id, teaching_staff_ids)
          school_class_params = school_class_params_from_context
          teacher_id_present = param_present?(school_class_params, :teacher_id)
          teaching_staff_ids_present = param_present?(school_class_params, :teaching_staff_ids)

          update_teacher_assignment(teacher_id) if teacher_id_present
          update_teaching_staff_assignment(teaching_staff_ids) if teaching_staff_ids_present
        end

        def school_class_params_from_context
          school_class_key = context.params[:school_class] || context.params['school_class']
          if school_class_key.is_a?(Hash) || school_class_key.is_a?(ActionController::Parameters)
            return school_class_key
          end

          nil
        end

        def param_present?(params_hash, key)
          return false unless params_hash

          params_hash.key?(key) || params_hash.key?(key.to_s)
        end

        def update_teacher_assignment(teacher_id)
          # Remove existing main teacher assignment for this class
          TeacherClassAssignment.where(school_class: context.school_class, role: 'main').destroy_all

          return if teacher_id.blank?

          teacher = User.joins(:user_roles)
                        .joins('INNER JOIN roles ON user_roles.role_id = roles.id')
                        .where(id: teacher_id, user_roles: { school_id: school.id }, roles: { key: 'teacher' })
                        .first
          return unless teacher

          # Create new assignment
          TeacherClassAssignment.find_or_create_by!(
            teacher: teacher,
            school_class: context.school_class,
            role: 'main'
          )
        end

        # rubocop:disable Metrics/MethodLength
        def update_teaching_staff_assignment(teaching_staff_ids)
          # Remove existing teaching staff assignments for this class
          TeacherClassAssignment.where(school_class: context.school_class, role: 'teaching_staff').destroy_all

          return if teaching_staff_ids.blank? || !teaching_staff_ids.is_a?(Array)

          # Get valid teachers from school, excluding main teacher if already assigned
          main_teacher_id = TeacherClassAssignment.where(school_class: context.school_class,
                                                         role: 'main').pluck(:teacher_id)
          valid_teacher_ids = teaching_staff_ids.reject { |id| main_teacher_id.include?(id) }

          return if valid_teacher_ids.empty?

          valid_teachers = User.joins(:user_roles)
                               .joins('INNER JOIN roles ON user_roles.role_id = roles.id')
                               .where(
                                 id: valid_teacher_ids,
                                 user_roles: { school_id: school.id },
                                 roles: { key: 'teacher' }
                               )

          # Create new assignments
          valid_teachers.each do |teacher|
            TeacherClassAssignment.find_or_create_by!(
              teacher: teacher,
              school_class: context.school_class,
              role: 'teaching_staff'
            )
          end
        end
        # rubocop:enable Metrics/MethodLength

        def class_params
          params = if context.params.is_a?(ActionController::Parameters)
                     context.params
                   else
                     ActionController::Parameters.new(context.params)
                   end
          params.require(:school_class).permit(:name, :year, :teacher_id, teaching_staff_ids: [], metadata: {})
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
      # rubocop:enable Metrics/ClassLength
    end
  end
end
