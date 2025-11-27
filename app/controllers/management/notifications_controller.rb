# frozen_string_literal: true

module Management
  class NotificationsController < Management::BaseController
    def index
      @status_filter = params[:status] || 'unread'
      @type_filter = params[:type] || 'all'
      @notifications = load_notifications(@status_filter, @type_filter)
      @unread_count = count_unread_notifications
    end

    private

    def load_notifications(status_filter = 'unread', type_filter = 'all')
      school = current_school_manager.school
      return [] unless school

      # Get current user's role
      user_role = current_school_manager.roles.pick(:key) || 'school_manager'

      # Build query
      query = Notification.for_school(school).for_role(user_role).recent

      # Filter by status
      query = if status_filter == 'archived'
                # Show resolved notifications or read notifications
                query.where('resolved_at IS NOT NULL OR read_at IS NOT NULL')
              else
                # Show unread and unresolved notifications
                query.unread.unresolved
              end

      # Filter by type
      query = query.where(notification_type: type_filter) if type_filter != 'all'

      # Convert to hash format for view
      query.map do |notification|
        build_notification_hash(notification)
      end
    end

    def build_notification_hash(notification)
      actions = build_notification_actions(notification)

      {
        id: notification.id.to_s,
        type: notification.notification_type,
        title: notification.title,
        message: notification.message,
        time_ago: helpers.time_ago_in_words(notification.created_at),
        created_at: notification.created_at,
        unread: !notification.read?,
        resolved: notification.resolved?,
        actions: actions
      }
    end

    def build_notification_actions(notification)
      actions = []

      case notification.notification_type
      when 'teacher_awaiting_approval'
        teacher_id = notification.metadata['teacher_id']
        if teacher_id
          actions << { label: 'View teacher', url: management_teachers_path, primary: true }
          unless notification.read?
            actions << { label: 'Mark as read', action: 'mark_read',
                         data: { notification_id: notification.id } }
          end
        end
      when 'student_awaiting_approval'
        student_id = notification.metadata['student_id']
        # actions << { label: 'View student', url: management_students_path, primary: true }
        if student_id && !notification.read?
          actions << { label: 'Mark as read', action: 'mark_read',
                       data: { notification_id: notification.id } }
        end
      else
        # Generic actions for other notification types
        unless notification.read?
          actions << { label: 'Mark as read', action: 'mark_read',
                       data: { notification_id: notification.id } }
        end
      end

      actions
    end

    def count_unread_notifications
      school = current_school_manager.school
      return 0 unless school

      user_role = current_school_manager.roles.pick(:key) || 'school_manager'

      Notification.for_school(school)
                  .for_role(user_role)
                  .unread
                  .unresolved
                  .count
    end
  end
end
