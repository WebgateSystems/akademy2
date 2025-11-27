# frozen_string_literal: true

module Management
  class BaseController < ApplicationController
    helper_method :current_school_manager
    helper_method :notifications_count
    helper_method :teachers_notifications_count
    helper_method :students_notifications_count

    before_action :authenticate_user!
    before_action :require_school_management_access!
    before_action :set_management_token
    before_action :set_notifications_counts

    layout 'management'

    private

    def current_school_manager
      @current_school_manager ||= current_user
    end

    def require_school_management_access!
      policy = SchoolManagementPolicy.new(current_user, :school_management)
      return if policy.access?

      redirect_to authenticated_root_path, alert: 'Brak uprawnień do zarządzania szkołą'
    end

    def set_management_token
      return unless current_user

      @management_token = Jwt::TokenService.encode({ user_id: current_user.id })
    end

    def set_notifications_counts
      @notifications_count = notifications_count
      @teachers_notifications_count = teachers_notifications_count
      @students_notifications_count = students_notifications_count
    end

    def notifications_count
      school = current_school_manager&.school
      return 0 unless school

      user_role = current_school_manager&.roles&.pick(:key) || 'school_manager'

      Notification.for_school(school)
                  .for_role(user_role)
                  .unread
                  .unresolved
                  .count
    end

    def teachers_notifications_count
      school = current_school_manager&.school
      return 0 unless school

      user_role = current_school_manager&.roles&.pick(:key) || 'school_manager'

      Notification.for_school(school)
                  .for_role(user_role)
                  .where(notification_type: 'teacher_awaiting_approval')
                  .unread
                  .unresolved
                  .count
    end

    def students_notifications_count
      school = current_school_manager&.school
      return 0 unless school

      user_role = current_school_manager&.roles&.pick(:key) || 'school_manager'

      Notification.for_school(school)
                  .for_role(user_role)
                  .where(notification_type: 'student_awaiting_approval')
                  .unread
                  .unresolved
                  .count
    end
  end
end
