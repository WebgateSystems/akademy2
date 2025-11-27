# frozen_string_literal: true

module Api
  module V1
    module Management
      class NotificationsController < Api::V1::Management::BaseController
        def mark_as_read
          notification_id = params[:notification_id]
          return render json: { error: 'Notification ID is required' }, status: :bad_request unless notification_id

          # Check if notification exists and is valid for this user
          school = current_user.school
          return render json: { error: 'School not found' }, status: :not_found unless school

          user_role = current_user.roles.pick(:key) || 'school_manager'

          notification = Notification.find_by(
            id: notification_id,
            school: school,
            target_role: user_role
          )

          return render json: { error: 'Notification not found' }, status: :not_found unless notification

          # Mark as read
          notification.mark_as_read!(current_user)

          # Log the event
          EventLogger.log(
            event_type: 'notification_read',
            user: current_user,
            school: school,
            data: {
              notification_id: notification.id,
              notification_type: notification.notification_type
            },
            client: 'web'
          )

          render json: { success: true, message: 'Notification marked as read' }, status: :ok
        rescue StandardError => e
          Rails.logger.error("Failed to mark notification as read: #{e.message}")
          render json: { error: 'Failed to mark notification as read' }, status: :internal_server_error
        end
      end
    end
  end
end
