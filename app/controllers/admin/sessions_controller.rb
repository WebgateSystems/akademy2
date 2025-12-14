class Admin::SessionsController < ApplicationController
  layout 'admin_auth'

  def new; end

  def create
    result = ::Api::V1::Sessions::CreateSession.call(params: { user: params })

    return handle_success(result) if result.success? && result.form.admin?

    handle_failure(result)
  end

  def destroy
    user_to_logout = current_admin
    reset_session
    EventLogger.log_logout(user: user_to_logout, client: 'admin') if user_to_logout
    redirect_to new_admin_session_path, notice: 'Logged out'
  end

  private

  def current_admin
    @current_admin ||= session[:admin_id] && decode_jwt(session[:admin_id])
  end

  def decode_jwt(token)
    decoded = ::Jwt::TokenService.decode(token)
    ::User.find_by(id: decoded['user_id'])
  rescue StandardError
    nil
  end

  def handle_success(result)
    # Clear redirect loop tracking on successful login
    session.delete(:last_redirect_path) if session[:last_redirect_path]

    session[:admin_id] = result.access_token

    # Check if user was trying to access a specific admin page
    stored_location = session[:return_to] || session[:user_return_to]
    if stored_location.present? && stored_location.start_with?('/admin')
      session.delete(:return_to)
      session.delete(:user_return_to)
      redirect_to stored_location, notice: t('admin.sessions.welcome')
    else
      redirect_to admin_root_path, notice: t('admin.sessions.welcome')
    end
  end

  def handle_failure(result)
    flash.now[:alert] = result.message || 'Invalid login or password'
    render :new, status: :unprocessable_entity
  end
end
