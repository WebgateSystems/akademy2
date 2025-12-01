# frozen_string_literal: true

module Api
  module V1
    module Management
      # rubocop:disable Metrics/ClassLength
      class UpdateStudent < BaseInteractor
        def call
          authorize!
          find_student
          update_student
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

        def find_student
          return context.fail!(message: ['Brak przypisanej szkoły']) unless school

          context.student = build_student_query.first

          return if context.student

          context.message = ['Uczeń nie został znaleziony']
          context.status = :not_found
          context.fail!
        end

        def build_student_query
          # Handle both hash and ActionController::Parameters
          student_id = get_param_value(:id)
          User.joins(:user_roles)
              .joins('INNER JOIN roles ON user_roles.role_id = roles.id')
              .joins('INNER JOIN student_class_enrollments ' \
                     'ON student_class_enrollments.student_id = users.id')
              .joins('INNER JOIN school_classes ' \
                     'ON school_classes.id = student_class_enrollments.school_class_id')
              .where(school_classes: { year: school.current_academic_year_value, school_id: school.id })
              .where(id: student_id,
                     user_roles: { school_id: school.id },
                     roles: { key: 'student' })
              .distinct
        end

        def update_student
          update_params = prepare_update_params
          return unless update_params

          if context.student.update(update_params)
            handle_class_assignment
            set_success_response
          else
            context.message = context.student.errors.full_messages
            context.fail!
          end
        end

        def prepare_update_params
          update_params = student_params.to_h
          merge_metadata(update_params)
          update_params[:school_id] = school.id
          update_params.delete(:school_class_id)
          handle_email_change(update_params)
          update_params
        end

        def handle_email_change(update_params)
          return unless update_params[:email].present? && context.student.email != update_params[:email]

          context.student.skip_reconfirmation!
        end

        def handle_class_assignment
          return if get_param_value(:student, :school_class_id).blank?

          update_class_assignment
        end

        def set_success_response
          context.form = context.student
          context.status = :ok
          context.serializer = StudentSerializer
        end

        def merge_metadata(update_params)
          return unless update_params[:metadata].present? || get_param_value(:student, :metadata, :phone).present?

          current_metadata = context.student.metadata || {}
          if update_params[:metadata].present?
            update_params[:metadata] = current_metadata.deep_merge(update_params[:metadata].symbolize_keys)
            # Extract birth_date from metadata and save to birthdate field
            if update_params[:metadata][:birth_date].present? && update_params[:birthdate].blank?
              update_params[:birthdate] = update_params[:metadata][:birth_date]
            end
          else
            update_params[:metadata] = current_metadata.merge(
              phone: get_param_value(:student, :metadata, :phone)
            )
          end
        end

        def update_class_assignment
          school_class_id = get_param_value(:student, :school_class_id)
          return unless school_class_id

          # Remove old enrollments for current academic year
          context.student.student_class_enrollments
                 .joins(:school_class)
                 .where(school_classes: { year: school.current_academic_year_value })
                 .destroy_all

          # Add new enrollment
          school_class = SchoolClass.find_by(id: school_class_id, school: school,
                                             year: school.current_academic_year_value)
          return unless school_class

          StudentClassEnrollment.find_or_create_by!(
            student: context.student,
            school_class: school_class
          )
        end

        def student_params
          # Convert to ActionController::Parameters if it's a hash
          params = if context.params.is_a?(ActionController::Parameters)
                     context.params
                   else
                     ActionController::Parameters.new(context.params)
                   end
          params.require(:student).permit(:first_name, :last_name, :email, :password,
                                          :password_confirmation, :school_class_id, :birthdate, metadata: {})
        end

        def get_param_value(*keys)
          if context.params.is_a?(ActionController::Parameters)
            context.params.dig(*keys)
          else
            keys.inject(context.params) { |hash, key| hash&.dig(key) }
          end
        end
      end
      # rubocop:enable Metrics/ClassLength
    end
  end
end
