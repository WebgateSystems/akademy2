module Register
  class SetPinConfirmSubmit < BaseInteractor
    def call
      valid_pin_and_match? ? process_success : fail_pin_mismatch
    end

    private

    def process_success
      save_pin_to_flow
      context.form = current_form

      save_user || fail_user_creation
    end

    def save_pin_to_flow
      context.flow.update(:pin, { 'pin' => current_form.pin })
    end

    def save_user
      user = build_user_from_flow

      unless user.save
        # rubocop:disable Rails/Output
        puts ''
        puts '=' * 60
        puts '❌ USER CREATION FAILED'
        puts '=' * 60
        puts "   Email: #{user.email}"
        puts "   Errors: #{user.errors.full_messages.join(', ')}"
        puts '=' * 60
        puts ''
        # rubocop:enable Rails/Output
        Rails.logger.error "[REGISTER] User creation failed: #{user.errors.full_messages.join(', ')}"
        return false
      end

      # Assign role based on registration type
      if teacher_registration?
        assign_teacher_role(user)
      else
        assign_student_role(user)
      end

      context.flow.update(:user, { 'user_id' => user.id })
      mark_verified!(user)
      true
    end

    def mark_verified!(user)
      metadata = user.metadata
      metadata['phone_verified'] = true
      user.update!(metadata: metadata)
    end

    def teacher_registration?
      # Check registration_type first (set in wizard controller)
      registration_type = context.flow['registration_type']
      return true if registration_type == 'teacher'
      return false if registration_type == 'student'

      # Fallback: if no registration_type, check if it's teacher registration
      # Teacher registration has school but no school_class
      school_data = context.flow['school']
      class_data = context.flow['school_class']

      school_data.present? && school_data['school_id'].present? && class_data.blank?
    end

    def assign_teacher_role(user)
      teacher_role = Role.find_by(key: 'teacher')
      return unless teacher_role

      school_data = context.flow['school']
      school = School.find_by(id: school_data['school_id']) if school_data

      if school
        # Create teacher role with school
        UserRole.create!(user: user, role: teacher_role, school: school)

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
        puts '✅ TEACHER ROLE ASSIGNED'
        puts '=' * 60
        puts "   User: #{user.email}"
        puts "   Phone: #{user.phone}"
        puts "   School: #{school.name}"
        puts '   Enrollment: pending approval'
        puts '=' * 60
        puts ''
        # rubocop:enable Rails/Output
      else
        # Fallback: create teacher role without school
        UserRole.create!(user: user, role: teacher_role, school: nil)
      end
    end

    def assign_student_role(user)
      student_role = Role.find_by(key: 'student')
      return unless student_role

      class_data = context.flow['school_class']
      if class_data.present? && class_data['school_class_id'].present?
        assign_student_role_with_class(user, student_role, class_data)
      else
        assign_student_role_without_school(user, student_role)
      end
    end

    def assign_student_role_with_class(user, student_role, class_data)
      school_class = SchoolClass.find_by(id: class_data['school_class_id'])
      school = school_class&.school

      if school_class && school
        create_student_with_class(user, student_role, school_class, school)
      else
        UserRole.create!(user: user, role: student_role, school: nil)
      end
    end

    def create_student_with_class(user, student_role, school_class, school)
      UserRole.create!(user: user, role: student_role, school: school)
      user.update!(school: school)

      StudentClassEnrollment.create!(
        student: user,
        school_class: school_class,
        status: 'pending'
      )

      NotificationService.create_student_enrollment_request(student: user, school_class: school_class)

      log_student_role_assigned_with_class(user, school, school_class)
    end

    def assign_student_role_without_school(user, student_role)
      UserRole.create!(user: user, role: student_role, school: nil)
      log_student_role_assigned(user)
    end

    def log_student_role_assigned_with_class(user, school, school_class)
      # rubocop:disable Rails/Output
      puts ''
      puts '=' * 60
      puts '✅ STUDENT ROLE ASSIGNED WITH CLASS'
      puts '=' * 60
      puts "   User: #{user.email}"
      puts "   Phone: #{user.phone}"
      puts "   School: #{school.name}"
      puts "   Class: #{school_class.name}"
      puts '   Enrollment: pending approval'
      puts '=' * 60
      puts ''
      # rubocop:enable Rails/Output
    end

    def log_student_role_assigned(user)
      # rubocop:disable Rails/Output
      puts ''
      puts '=' * 60
      puts '✅ STUDENT ROLE ASSIGNED'
      puts '=' * 60
      puts "   User: #{user.email}"
      puts "   Phone: #{user.phone}"
      puts '   School: (none - will join via invitation)'
      puts '=' * 60
      puts ''
      # rubocop:enable Rails/Output
    end

    def fail_user_creation
      user = build_user_from_flow
      user.valid? # trigger validation to populate errors
      context.redirect_path = redirect_to_profile
      context.fail!(message: user.errors.full_messages.to_sentence)
    end

    def fail_pin_mismatch
      context.form = current_form
      context.fail!(message: 'Codes do not match')
    end

    def redirect_to_profile
      Rails.application.routes.url_helpers.register_profile_path
    end

    def valid_pin_and_match?
      current_form.valid? && current_form.pin == stored_pin
    end

    def current_form
      @current_form ||= PinForm.new(pin: submitted_pin)
    end

    def submitted_pin
      context.params[:pin_hidden]
    end

    def stored_pin
      context.flow['pin_temp']['pin']
    end

    def build_user_from_flow
      Register::BuildUserFromFlow.call(flow: context.flow).user
    end
  end
end
