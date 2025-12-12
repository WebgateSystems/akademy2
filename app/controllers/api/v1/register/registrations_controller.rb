# frozen_string_literal: true

module Api
  module V1
    module Register
      class RegistrationsController < ApplicationApiController
        # POST /api/v1/register/student - registers a new student (PIN 4 digits, optional class_token)
        def student
          render_registration_result(create_user(role: 'student'))
        end

        # POST /api/v1/register/teacher - registers a new teacher (password, optional school_token)
        def teacher
          render_registration_result(create_user(role: 'teacher'))
        end

        private

        def render_registration_result(result)
          if result[:success]
            render json: result[:data], status: :created
          else
            render json: { errors: result[:errors] }, status: :unprocessable_entity
          end
        end

        def create_user(role:)
          user = User.new(user_params)
          user.skip_confirmation_notification!

          if user.save
            assign_role_and_enrollment(user, role)
            user.send_confirmation_instructions
            success_response(user, role)
          else
            { success: false, errors: user.errors.full_messages }
          end
        end

        def success_response(user, role)
          {
            success: true,
            data: {
              user_id: user.id,
              email: user.email,
              role: role,
              status: 'pending_approval',
              school_id: user.school_id,
              access_token: generate_access_token(user)
            }
          }
        end

        def user_params
          params.require(:user).permit(
            :email, :password, :password_confirmation,
            :first_name, :last_name, :phone, :locale
          )
        end

        def assign_role_and_enrollment(user, role_key)
          case role_key
          when 'student'
            assign_student_role(user)
          when 'teacher'
            assign_teacher_role(user)
          end
        end

        def assign_student_role(user)
          student_role = Role.find_by!(key: 'student')
          token = params[:class_token] || params[:join_token]

          if token.present?
            assign_student_with_class(user, student_role, token)
          else
            UserRole.create!(user: user, role: student_role, school: nil)
          end
        end

        def assign_student_with_class(user, student_role, token)
          # rubocop:disable Rails/DynamicFindBy
          school_class = SchoolClass.find_by_join_token(token)
          # rubocop:enable Rails/DynamicFindBy
          return UserRole.create!(user: user, role: student_role, school: nil) unless school_class

          school = school_class.school
          UserRole.create!(user: user, role: student_role, school: school)
          user.update!(school: school)

          StudentClassEnrollment.create!(
            student: user,
            school_class: school_class,
            status: 'pending'
          )

          NotificationService.create_student_enrollment_request(student: user, school_class: school_class)
        end

        def assign_teacher_role(user)
          teacher_role = Role.find_by!(key: 'teacher')
          token = params[:school_token] || params[:join_token]

          if token.present?
            assign_teacher_with_school(user, teacher_role, token)
          else
            UserRole.create!(user: user, role: teacher_role, school: nil)
          end
        end

        def assign_teacher_with_school(user, teacher_role, token)
          # rubocop:disable Rails/DynamicFindBy
          school = School.find_by_join_token(token)
          # rubocop:enable Rails/DynamicFindBy
          return UserRole.create!(user: user, role: teacher_role, school: nil) unless school

          UserRole.create!(user: user, role: teacher_role, school: school)
          user.update!(school: school)

          TeacherSchoolEnrollment.create!(
            teacher: user,
            school: school,
            status: 'pending'
          )

          NotificationService.create_teacher_enrollment_request(teacher: user, school: school)
        end

        def generate_access_token(user)
          Jwt::TokenService.encode({ user_id: user.id }, 24.hours.from_now)
        end
      end
    end
  end
end
