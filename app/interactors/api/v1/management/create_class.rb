# frozen_string_literal: true

module Api
  module V1
    module Management
      # rubocop:disable Metrics/ClassLength
      class CreateClass < BaseInteractor
        def call
          authorize!
          build_class
          save_class
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

        def build_class
          return context.fail!(message: ['Brak przypisanej szkoły']) unless school

          params_hash = class_params.to_h
          # Remove teacher_id and teaching_staff_ids as they're not SchoolClass attributes
          params_hash.delete(:teacher_id)
          params_hash.delete(:teaching_staff_ids)
          params_hash[:school_id] = school.id
          params_hash[:qr_token] = SecureRandom.uuid if params_hash[:qr_token].blank?
          params_hash[:metadata] = {} if params_hash[:metadata].blank?

          context.school_class = SchoolClass.new(params_hash)
        end

        def save_class
          if context.school_class.save
            assign_teacher if get_param_value(:school_class, :teacher_id).present?
            assign_teaching_staff if get_param_value(:school_class, :teaching_staff_ids).present?
            # Reload to ensure associations are loaded
            context.school_class.reload
            context.form = context.school_class
            context.status = :created
            context.serializer = SchoolClassSerializer
          else
            context.message = context.school_class.errors.full_messages
            context.fail!
          end
        end

        def assign_teacher
          teacher_id = get_param_value(:school_class, :teacher_id)
          return unless teacher_id

          teacher = User.joins(:user_roles)
                        .joins('INNER JOIN roles ON user_roles.role_id = roles.id')
                        .where(id: teacher_id, user_roles: { school_id: school.id }, roles: { key: 'teacher' })
                        .first
          return unless teacher

          # Remove existing main teacher assignment for this class
          TeacherClassAssignment.where(school_class: context.school_class, role: 'main').destroy_all

          # Create new assignment
          TeacherClassAssignment.find_or_create_by!(
            teacher: teacher,
            school_class: context.school_class,
            role: 'main'
          )
        end

        def assign_teaching_staff
          teaching_staff_ids = get_param_value(:school_class, :teaching_staff_ids)
          return unless teaching_staff_ids.is_a?(Array) && teaching_staff_ids.any?

          # Remove existing teaching staff assignments for this class
          TeacherClassAssignment.where(school_class: context.school_class, role: 'teaching_staff').destroy_all

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
