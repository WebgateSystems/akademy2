# frozen_string_literal: true

module Management
  class BaseController < ApplicationController
    helper_method :current_school_manager
    helper_method :notifications_count
    helper_method :teachers_notifications_count
    helper_method :students_notifications_count
    helper_method :current_academic_year

    before_action :require_management_login!
    before_action :set_management_token
    before_action :set_notifications_counts

    layout 'management'

    private

    def current_school_manager
      @current_school_manager ||= current_user
    end

    def require_management_login!
      # First check if user is signed in at all
      unless user_signed_in?
        session[:user_return_to] = request.fullpath
        # rubocop:disable I18n/GetText/DecorateString
        redirect_to administration_login_path,
                    alert: 'Zaloguj się, aby uzyskać dostęp do panelu zarządzania szkołą.'
        # rubocop:enable I18n/GetText/DecorateString
        return
      end

      # Check if user has management permissions
      policy = SchoolManagementPolicy.new(current_user, :school_management)
      return if policy.access?

      # User is logged in but doesn't have management access - sign them out first
      sign_out(current_user)
      session.delete(:return_to)
      session.delete(:user_return_to)

      # Redirect to login with administration role parameter
      # rubocop:disable I18n/GetText/DecorateString
      redirect_to administration_login_path,
                  alert: 'Brak uprawnień do zarządzania szkołą. Zaloguj się kontem z odpowiednimi uprawnieniami.'
      # rubocop:enable I18n/GetText/DecorateString
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

    def current_academic_year
      school = current_school_manager&.school
      return '2025/2026' unless school

      school.current_academic_year_value
    end
  end
end
