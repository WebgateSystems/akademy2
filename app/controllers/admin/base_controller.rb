class Admin::BaseController < ApplicationController
  helper_method :current_admin
  helper_method :notifications_count

  before_action :authenticate_admin!
  before_action :require_admin!
  before_action :set_notifications_count

  layout 'admin'

  private

  def authenticate_admin!
    redirect_to new_admin_session_path unless current_admin
  end

  def current_admin
    @current_admin ||= session[:admin_id] && decode_jwt(session[:admin_id])
  end

  def decode_jwt(token)
    return nil unless token

    decoded = ::Jwt::TokenService.decode(token)
    return nil unless decoded.is_a?(Hash)

    ::User.find_by(id: decoded['user_id'])
  rescue StandardError
    nil
  end

  def logout
    session.delete(:admin_id)
    redirect_to new_admin_session_path, notice: 'Logged out'
  end

  def require_admin!
    redirect_to new_admin_session_path unless current_admin&.admin?
  end

  def set_notifications_count
    @notifications_count = notifications_count
  end

  def notifications_count
    Notification.for_role('admin')
                .unread
                .unresolved
                .count
  end
end
