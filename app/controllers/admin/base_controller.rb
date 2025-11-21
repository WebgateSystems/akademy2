class Admin::BaseController < ApplicationController
  helper_method :current_admin

  before_action :authenticate_admin!
  before_action :require_admin!

  layout 'admin'

  private

  def authenticate_admin!
    redirect_to new_admin_session_path unless current_admin
  end

  def current_admin
    @current_admin ||= session[:admin_id] && decode_jwt(session[:admin_id])
  end

  def decode_jwt(token)
    session = ::Jwt::TokenService.decode(token)
    ::User.find_by(id: session['user_id'])
  rescue StandardError
    logout
  end

  def logout
    session.delete(:admin_id)
    redirect_to admin_login_path, notice: 'Logged out'
  end

  def require_admin!
    redirect_to new_admin_session_path unless current_admin&.admin?
  end
end
