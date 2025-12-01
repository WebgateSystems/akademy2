# frozen_string_literal: true

module Api
  module V1
    module Management
      class SearchStudentsForParent < BaseInteractor
        def call
          authorize!
          search_students
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

        def search_students
          return context.fail!(message: ['Brak przypisanej szkoły']) unless school

          search_term = context.params[:search] || context.params[:q]
          return context.fail!(message: ['Brak terminu wyszukiwania']) if search_term.blank?

          current_year = school.current_academic_year_value
          students = build_students_query(current_year, "%#{search_term}%")

          context.form = students.map { |student| serialize_student(student, current_year) }
          context.status = :ok
        end

        def build_students_query(current_year, search_pattern)
          User.joins(:user_roles)
              .joins('INNER JOIN roles ON user_roles.role_id = roles.id')
              .joins('INNER JOIN student_class_enrollments ' \
                     'ON student_class_enrollments.student_id = users.id')
              .joins('INNER JOIN school_classes ' \
                     'ON school_classes.id = student_class_enrollments.school_class_id')
              .where(user_roles: { school_id: school.id }, roles: { key: 'student' })
              .where(school_classes: { year: current_year, school_id: school.id })
              .where('users.first_name ILIKE ? OR users.last_name ILIKE ?', search_pattern, search_pattern)
              .includes(student_class_enrollments: :school_class)
              .distinct
              .limit(20)
        end

        def serialize_student(student, current_year)
          current_class = student.student_class_enrollments
                                 .find { |enrollment| enrollment.school_class.year == current_year }
          {
            id: student.id,
            first_name: student.first_name,
            last_name: student.last_name,
            birthdate: format_birthdate(student),
            class_name: current_class&.school_class&.name || '—',
            email: student.email
          }
        end

        def format_birthdate(student)
          return student.birthdate.strftime('%d.%m.%Y') if student.birthdate.present?

          student.metadata&.dig('birth_date')
        end
      end
    end
  end
end
