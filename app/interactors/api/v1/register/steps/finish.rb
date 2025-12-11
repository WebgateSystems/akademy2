module Api
  module V1
    module Register
      module Steps
        class Finish < BaseInteractor
          def call
            return not_found unless flow
            return bad_outcome unless current_form.valid?

            user = build_user
            user.save ? after_success(user) : user_failed(user)
          end

          private

          def flow
            @flow ||= RegistrationFlow.find_by(id: context.params[:flow_id])
          end

          def current_form
            @current_form ||= Api::Register::ProfileForm.new(flow.data['profile'])
          end

          def invalid_step
            context.fail!(
              message: ['Step order is invalid'],
              status: :unprocessable_entity
            )
          end

          def build_user
            profile = flow.data['profile']

            User.new(
              first_name: profile['first_name'],
              last_name: profile['last_name'],
              birthdate: profile['birthdate'],
              email: profile['email'],
              phone: flow.data.dig('phone', 'number'),
              password: flow.pin_temp,
              password_confirmation: flow.pin_temp
            )
          end

          def authentificate_user(user)
            context.session_service = Api::V1::Sessions::CreateSession.call(
              params: {
                user: {
                  email: user.email,
                  password: user.password
                }
              }
            )
          end

          def after_success(user)
            authentificate_user(user)

            if student_registered_with_class_token?
              create_student_with_enrollment(user)
            else
              create_student_without_school(user)
            end

            user.send_confirmation_instructions
            flow.destroy!

            context.form = user
            context.access_token = context.session_service.access_token
            context.status = :created
          end

          def student_registered_with_class_token?
            class_data = flow.data['school_class']
            class_data.present? && class_data['school_class_id'].present?
          end

          def create_student_with_enrollment(user)
            class_data = flow.data['school_class']
            school_class = SchoolClass.find_by(id: class_data['school_class_id'])
            school = school_class&.school

            return unless school_class && school

            student_role = Role.find_by(key: 'student')
            return unless student_role

            UserRole.create!(user: user, role: student_role, school: school)
            user.update!(school: school)

            StudentClassEnrollment.create!(
              student: user,
              school_class: school_class,
              status: 'pending'
            )

            NotificationService.create_student_enrollment_request(student: user, school_class: school_class)
          end

          def create_student_without_school(user)
            student_role = Role.find_by(key: 'student')
            UserRole.create!(user: user, role: student_role, school: nil) if student_role
          end

          def user_failed(user)
            context.message = user.errors.messages
            context.errors = user.errors
            context.status = :unprocessable_entity
            context.fail!
          end
        end
      end
    end
  end
end
