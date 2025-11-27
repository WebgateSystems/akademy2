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
  def self.create_student_awaiting_approval(student:, school:)
    return if student.confirmed_at.present?

    # Create notification for school managers
    school_managers = User.joins(:user_roles)
                          .joins('INNER JOIN roles ON user_roles.role_id = roles.id')
                          .where(user_roles: { school_id: school.id },
                                 roles: { key: %w[principal school_manager] })
                          .distinct

    student_name = [student.first_name, student.last_name].compact.join(' ').presence || student.email

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
