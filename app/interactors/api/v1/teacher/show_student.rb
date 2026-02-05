# frozen_string_literal: true

module Api
  module V1
    module Teacher
      class ShowStudent < BaseInteractor
        def call
          authorize!
          find_student
        end

        private

        def authorize!
          return if current_user && teacher_role?

          context.fail!(message: ['Brak uprawnień'])
        end

        def teacher_role?
          current_user.user_roles.joins(:role).exists?(roles: { key: 'teacher' })
        end

        def current_user = context.current_user

        def school
          @school ||= current_user.school || current_user.user_roles.joins(:role)
                                                         .where(roles: { key: 'teacher' }).first&.school
        end

        def find_student
          return context.fail!(message: ['Brak przypisanej szkoły']) unless school

          student = find_student_in_teacher_classes
          return assign_success_context(student) if student

          context.fail!(message: ['Uczeń nie został znaleziony'], status: :not_found)
        end

        def find_student_in_teacher_classes
          teacher_class_ids = TeacherClassAssignment.where(teacher: current_user).pluck(:school_class_id)
          return nil if teacher_class_ids.empty?

          User.joins(:student_class_enrollments)
              .where(id: context.params[:id],
                     student_class_enrollments: { school_class_id: teacher_class_ids })
              .distinct.first
        end

        def assign_success_context(student)
          context.form = student
          context.status = :ok
          context.serializer = StudentSerializer
        end
      end
    end
  end
end
