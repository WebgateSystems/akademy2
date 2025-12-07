# frozen_string_literal: true

module Management
  class NotificationsController < Management::BaseController
    def index
      @status_filter = params[:status] || 'unread'
      @type_filter = params[:type] || 'all'
      @notifications = load_notifications(@status_filter, @type_filter)
      @unread_count = count_unread_notifications
    end

    # POST /management/notifications/:id/approve_account_deletion
    def approve_account_deletion
      notification = find_notification
      return redirect_to management_notifications_path, alert: 'Notification not found' unless notification

      student_id = notification.metadata['user_id']
      student = User.find_by(id: student_id)

      if student
        student_name = student.full_name
        # Delete the student account
        student.destroy
        NotificationService.resolve_account_deletion_request(notification: notification)

        redirect_to management_notifications_path,
                    notice: I18n.t('management.notifications.account_deletion_approved',
                                   user_name: student_name,
                                   default: "Account for #{student_name} has been deleted.")
      else
        notification.update!(resolved_at: Time.current, read_at: Time.current)
        redirect_to management_notifications_path,
                    alert: I18n.t('management.notifications.student_not_found')
      end
    end

    # POST /management/notifications/:id/reject_account_deletion
    def reject_account_deletion
      notification = find_notification
      return redirect_to management_notifications_path, alert: 'Notification not found' unless notification

      student_id = notification.metadata['user_id']
      student = User.find_by(id: student_id)

      # Mark notification as resolved (rejected)
      NotificationService.resolve_account_deletion_request(notification: notification)

      # Create a notification for the student that their request was rejected
      if student
        NotificationService.create_account_deletion_rejected(
          student: student,
          moderator: current_user,
          notification: notification
        )
      end

      student_name = notification.metadata['user_name'] || 'Unknown'
      redirect_to management_notifications_path,
                  notice: I18n.t('management.notifications.account_deletion_rejected',
                                 user_name: student_name,
                                 default: "Account deletion request for #{student_name} was rejected.")
    end

    private

    def find_notification
      school = current_school_manager.school
      return nil unless school

      Notification.for_school(school).find_by(id: params[:id])
    end

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
      when 'account_deletion_request'
        student_id = notification.metadata['student_id']
        if student_id && !notification.resolved?
          actions << {
            label: 'Approve deletion',
            action: 'approve_deletion',
            url: approve_account_deletion_management_notification_path(notification),
            method: :post,
            primary: true,
            danger: true
          }
          actions << {
            label: 'Reject',
            action: 'reject_deletion',
            url: reject_account_deletion_management_notification_path(notification),
            method: :post
          }
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
