# frozen_string_literal: true

module Admin
  class NotificationsController < Admin::BaseController
    def index
      @status_filter = params[:status] || 'unread'
      @type_filter = params[:type] || 'all'
      @notifications = load_notifications(@status_filter, @type_filter)
      @unread_count = notifications_count
    end

    def mark_as_read
      notification = Notification.find_by(id: params[:notification_id])
      return render json: { success: false, error: 'Notification not found' }, status: :not_found unless notification

      # mark_as_read! returns false if already read, but that's OK
      notification.mark_as_read!(current_admin)
      render json: { success: true }
    end

    private

    def load_notifications(status_filter = 'unread', type_filter = 'all')
      # Get all notifications for admin role (no school filtering)
      query = Notification.for_role('admin').recent

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

      # Add "Mark as read" action for unread notifications
      unless notification.read?
        actions << {
          label: 'Mark as read',
          action: 'mark_read',
          data: { notification_id: notification.id.to_s }
        }
      end

      # Add specific actions based on notification type
      case notification.notification_type
      when 'teacher_awaiting_approval'
        if notification.school
          actions << {
            label: 'View school',
            url: admin_resource_path(resource: 'schools', id: notification.school.id),
            primary: true
          }
        end
      when 'student_awaiting_approval'
        if notification.school
          actions << {
            label: 'View school',
            url: admin_resource_path(resource: 'schools', id: notification.school.id),
            primary: true
          }
        end
      end

      actions
    end
  end
end
