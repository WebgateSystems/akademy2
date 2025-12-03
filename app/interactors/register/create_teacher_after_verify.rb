module Register
  class CreateTeacherAfterVerify < BaseInteractor
    def call
      profile = context.flow['profile']
      existing_user = User.find_by(email: profile['email'])

      if existing_user
        # User already exists - update password if needed and assign teacher role
        handle_existing_user(existing_user, profile)
      else
        # Create new user
        user = build_teacher_user
        return context.fail!(message: user.errors.full_messages.to_sentence) unless user.save

        assign_teacher_role(user)
        context.user = user
      end
    end

    private

    def handle_existing_user(user, profile)
      # Update password if provided and different
      if profile['password'].present? && profile['password'] == profile['password_confirmation']
        user.password = profile['password']
        user.password_confirmation = profile['password_confirmation']
        user.save
      end

      # Update other fields if needed
      update_attrs = {}
      update_attrs[:first_name] = profile['first_name'] if profile['first_name'].present?
      update_attrs[:last_name] = profile['last_name'] if profile['last_name'].present?
      update_attrs[:phone] = profile['phone'] if profile['phone'].present?
      user.update(update_attrs) if update_attrs.any?

      assign_teacher_role(user)
      context.user = user
    end

    def build_teacher_user
      profile = context.flow['profile']
      User.new(
        first_name: profile['first_name'],
        last_name: profile['last_name'],
        email: profile['email'],
        phone: profile['phone'],
        password: profile['password'],
        password_confirmation: profile['password_confirmation']
      )
    end

    def assign_teacher_role(user)
      teacher_role = Role.find_by(key: 'teacher')
      return unless teacher_role

      school_data = context.flow['school']
      # Find school by join_token
      school = School.find_by(join_token: school_data['join_token']) if school_data&.dig('join_token')

      existing_role = user.user_roles.joins(:role).find_by(roles: { key: 'teacher' })
      if school
        # Check if teacher role already exists
        unless existing_role
          # Create teacher role WITHOUT school - school will be assigned after enrollment approval
          UserRole.create!(user: user, role: teacher_role, school: nil)
        end

        # Check if enrollment already exists
        existing_enrollment = user.teacher_school_enrollments.find_by(school: school)
        unless existing_enrollment
          # Create enrollment request (pending approval)
          TeacherSchoolEnrollment.create!(
            teacher: user,
            school: school,
            status: 'pending'
          )

          # Create notification for school managers
          NotificationService.create_teacher_enrollment_request(teacher: user, school: school)

          # rubocop:disable Rails/Output
          puts ''
          puts '=' * 60
          puts '✅ TEACHER ENROLLMENT REQUEST SENT'
          puts '=' * 60
          puts "   User: #{user.email}"
          puts "   Phone: #{user.phone}"
          puts "   School: #{school.name}"
          puts '   Enrollment: pending approval'
          puts '   UserRole: created WITHOUT school (will be assigned after approval)'
          puts '=' * 60
          puts ''
          # rubocop:enable Rails/Output
        end
      else
        # Fallback: create teacher role without school (only if doesn't exist)
        UserRole.create!(user: user, role: teacher_role, school: nil) unless existing_role
      end
    end
  end
end
