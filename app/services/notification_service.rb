# frozen_string_literal: true

class NotificationService
  # Create a notification for teacher awaiting approval
  def self.create_teacher_awaiting_approval(teacher:, school:)
    return if teacher.confirmed_at.present?

    # Create notification for all school managers and principals
    school_managers = User.joins(:user_roles)
                          .joins('INNER JOIN roles ON user_roles.role_id = roles.id')
                          .where(user_roles: { school_id: school.id },
                                 roles: { key: %w[principal school_manager] })
                          .distinct

    teacher_name = [teacher.first_name, teacher.last_name].compact.join(' ').presence || teacher.email

    school_managers.find_each do |manager|
      role_key = manager.roles.pick(:key) || 'school_manager'

      # Check if notification already exists and is unresolved
      existing = Notification.where(
        notification_type: 'teacher_awaiting_approval',
        target_role: role_key,
        school: school,
        resolved_at: nil
      ).where("metadata->>'teacher_id' = ?", teacher.id.to_s).first

      next if existing

      Notification.create!(
        notification_type: 'teacher_awaiting_approval',
        title: 'New teacher joined',
        message: "#{teacher_name} is awaiting approval.",
        target_role: role_key,
        school: school,
        user: teacher,
        metadata: { teacher_id: teacher.id }
      )
    end
  end

  # Mark teacher notification as resolved when teacher is approved
  def self.resolve_teacher_notification(teacher:, school:)
    notifications = Notification.where(
      notification_type: 'teacher_awaiting_approval',
      school: school,
      resolved_at: nil
    ).where("metadata->>'teacher_id' = ?", teacher.id.to_s)

    notifications.find_each do |notification|
      notification.update!(resolved_at: Time.current)
    end
  end

  # Resolve student notification when student is approved
  def self.resolve_student_notification(student:, school:)
    notifications = Notification.where(
      notification_type: 'student_awaiting_approval',
      school: school,
      resolved_at: nil
    ).where("metadata->>'student_id' = ?", student.id.to_s)

    notifications.find_each do |notification|
      notification.update!(resolved_at: Time.current)
    end
  end

  # Create notification for student awaiting approval
  def self.create_student_awaiting_approval(student:, school:, school_class: nil)
    return if student.confirmed_at.present?

    student_name = [student.first_name, student.last_name].compact.join(' ').presence || student.email

    # Create notification for school managers
    school_managers = User.joins(:user_roles)
                          .joins('INNER JOIN roles ON user_roles.role_id = roles.id')
                          .where(user_roles: { school_id: school.id },
                                 roles: { key: %w[principal school_manager] })
                          .distinct

    school_managers.find_each do |manager|
      Notification.find_or_create_by(
        notification_type: 'student_awaiting_approval',
        target_role: manager.roles.pick(:key),
        school: school,
        metadata: { student_id: student.id },
        read_at: nil
      ) do |notification|
        notification.title = 'New student joined'
        notification.message = "#{student_name} is awaiting approval."
        notification.user = student
      end
    end

    # Create notification for teachers of the student's class
    return unless school_class

    teachers = User.joins(:teacher_class_assignments)
                   .where(teacher_class_assignments: { school_class_id: school_class.id })
                   .distinct

    teachers.find_each do |_teacher|
      Notification.find_or_create_by(
        notification_type: 'student_awaiting_approval',
        target_role: 'teacher',
        school: school,
        metadata: { student_id: student.id, school_class_id: school_class.id },
        read_at: nil
      ) do |notification|
        notification.title = 'Nowy uczeń w klasie'
        notification.message = "#{student_name} oczekuje na akceptację w klasie #{school_class.name}."
        notification.user = student
      end
    end
  end

  # Create notification for teachers when student completes quiz with score >= 80
  def self.create_quiz_success_notification(student:, quiz_result:)
    school = student.school
    return unless school

    # Get student's class(es)
    student_classes = student.student_class_enrollments.where(status: 'approved').includes(:school_class)
    return if student_classes.empty?

    student_name = [student.first_name, student.last_name].compact.join(' ').presence || student.email
    learning_module = quiz_result.learning_module
    module_title = learning_module&.title || 'Quiz'

    # Notify teachers of the student's classes
    student_classes.each do |enrollment|
      school_class = enrollment.school_class
      next unless school_class

      teachers = User.joins(:teacher_class_assignments)
                     .where(teacher_class_assignments: { school_class_id: school_class.id })
                     .distinct

      teachers.find_each do |_teacher|
        Notification.create!(
          notification_type: 'quiz_completed',
          title: 'Sukces ucznia!',
          message: "#{student_name} ukończył/a quiz \"#{module_title}\" z wynikiem #{quiz_result.score} punktów.",
          target_role: 'teacher',
          school: school,
          user: student,
          metadata: {
            student_id: student.id,
            quiz_result_id: quiz_result.id,
            school_class_id: school_class.id,
            score: quiz_result.score
          }
        )
      end
    end
  end

  # Create notification for teachers when student requests to join their class
  def self.create_student_enrollment_request(student:, school_class:)
    school = school_class.school
    return unless school

    student_name = [student.first_name, student.last_name].compact.join(' ').presence || student.phone || 'Uczeń'

    # Get teachers assigned to this class
    teachers = User.joins(:teacher_class_assignments)
                   .where(teacher_class_assignments: { school_class_id: school_class.id })
                   .distinct

    teachers.find_each do |_teacher|
      # Check if notification already exists and is unresolved
      existing = Notification.where(
        notification_type: 'student_enrollment_request',
        target_role: 'teacher',
        school: school,
        resolved_at: nil
      ).where("metadata->>'student_id' = ? AND metadata->>'school_class_id' = ?",
              student.id.to_s, school_class.id.to_s).first

      next if existing

      Notification.create!(
        notification_type: 'student_enrollment_request',
        title: 'Nowy wniosek o dołączenie',
        message: "#{student_name} chce dołączyć do klasy #{school_class.name}.",
        target_role: 'teacher',
        school: school,
        user: student,
        metadata: {
          student_id: student.id,
          school_class_id: school_class.id,
          enrollment_type: 'pending'
        }
      )
    end
  end

  # Resolve student enrollment request notification
  def self.resolve_student_enrollment_request(student:, school_class:)
    school = school_class.school
    return unless school

    notifications = Notification.where(
      notification_type: 'student_enrollment_request',
      school: school,
      resolved_at: nil
    ).where("metadata->>'student_id' = ? AND metadata->>'school_class_id' = ?",
            student.id.to_s, school_class.id.to_s)

    notifications.find_each do |notification|
      notification.update!(resolved_at: Time.current)
    end
  end

  # Create notification for school managers when teacher requests to join their school
  def self.create_teacher_enrollment_request(teacher:, school:)
    return unless school

    teacher_name = [teacher.first_name, teacher.last_name].compact.join(' ').presence || teacher.email || 'Nauczyciel'

    # Get school managers and principals
    school_managers = User.joins(:user_roles)
                          .joins('INNER JOIN roles ON user_roles.role_id = roles.id')
                          .where(user_roles: { school_id: school.id },
                                 roles: { key: %w[principal school_manager] })
                          .distinct

    school_managers.find_each do |manager|
      role_key = manager.roles.pick(:key) || 'school_manager'

      # Check if notification already exists and is unresolved
      existing = Notification.where(
        notification_type: 'teacher_enrollment_request',
        target_role: role_key,
        school: school,
        resolved_at: nil
      ).where("metadata->>'teacher_id' = ?", teacher.id.to_s).first

      next if existing

      Notification.create!(
        notification_type: 'teacher_enrollment_request',
        title: 'Nowy wniosek o dołączenie',
        message: "#{teacher_name} chce dołączyć do szkoły #{school.name}.",
        target_role: role_key,
        school: school,
        user: teacher,
        metadata: {
          teacher_id: teacher.id,
          enrollment_type: 'pending'
        }
      )
    end
  end

  # Resolve teacher enrollment request notification
  def self.resolve_teacher_enrollment_request(teacher:, school:)
    return unless school

    notifications = Notification.where(
      notification_type: 'teacher_enrollment_request',
      school: school,
      resolved_at: nil
    ).where("metadata->>'teacher_id' = ?", teacher.id.to_s)

    notifications.find_each do |notification|
      notification.update!(resolved_at: Time.current)
    end
  end

  # Generic method to create notifications
  # rubocop:disable Metrics/ParameterLists
  def self.create_notification(notification_type:, title:, message:, target_role:, user: nil, school: nil, metadata: {})
    Notification.create!(
      notification_type: notification_type,
      title: title,
      message: message,
      target_role: target_role,
      user: user,
      school: school,
      metadata: metadata
    )
  end
  # rubocop:enable Metrics/ParameterLists
end
