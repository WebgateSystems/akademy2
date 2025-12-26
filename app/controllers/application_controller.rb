class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  include Pundit::Authorization

  before_action :check_user_active
  before_action :check_redirect_loop

  rescue_from Pundit::NotAuthorizedError do
    fallback = if respond_to?(:admin_root_path)
                 admin_root_path
               else
                 (respond_to?(:new_user_session_path) ? new_user_session_path : 'up')
               end
    # rubocop:disable I18n/GetText/DecorateString
    redirect_to(request.referer.presence || fallback, alert: 'Brak uprawnień.')
    # rubocop:enable I18n/GetText/DecorateString
  end

  # Redirect after sign in based on stored location or user roles
  def after_sign_in_path_for(resource)
    return super unless resource.is_a?(User)

    # First, check if user was trying to access a specific page (stored by Devise or custom session)
    stored_location = stored_location_for(resource) || session[:return_to]
    return handle_stored_location(stored_location) if stored_location.present?

    # If no stored location, use default based on roles
    redirect_path_for_user_roles(resource)
  end

  private

  def handle_stored_location(stored_location)
    session.delete(:return_to)
    stored_location
  end

  def redirect_path_for_user_roles(user)
    user_roles = user.roles.pluck(:key)
    return admin_root_path if user_roles.include?('admin')
    return admin_root_path if user_roles.include?('manager')
    return dashboard_path if user_roles.include?('teacher')
    return management_root_path if management_role?(user_roles)
    return public_home_path if user_roles.include?('student')

    # Users without any relevant roles will be handled by redirect loop detection
    # Redirect to root (landing page) - they shouldn't be logged in anyway
    root_path
  end

  def management_role?(user_roles)
    user_roles.include?('principal') || user_roles.include?('school_manager')
  end

  # Check if logged in user is still active (not locked)
  # If user was deactivated while logged in, sign them out
  def check_user_active
    return unless respond_to?(:user_signed_in?) && user_signed_in?
    return unless respond_to?(:current_user) && current_user.present?
    return if current_user.active?

    sign_out current_user
    # rubocop:disable I18n/GetText/DecorateString
    redirect_to new_user_session_path, alert: 'Twoje konto zostało dezaktywowane. Skontaktuj się z administratorem.'
    # rubocop:enable I18n/GetText/DecorateString
  end

  def check_redirect_loop
    return unless user_signed_in?

    current_path = request.path
    return if should_skip_redirect_check?(current_path)

    last_path = session[:last_redirect_path]
    redirect_count = session[:last_redirect_count] || 0
    last_time = session[:last_redirect_time]

    reset_tracking_if_expired(last_time, last_path, redirect_count)
    last_path = session[:last_redirect_path] # Re-read after potential reset
    redirect_count = session[:last_redirect_count] || 0

    handle_redirect_tracking(current_path, last_path, redirect_count)
  end

  def user_signed_in?
    current_user.present? || (respond_to?(:user_signed_in?) && user_signed_in?)
  end

  def should_skip_redirect_check?(current_path)
    current_path.include?('/sign_in') ||
      current_path.start_with?('/api/') ||
      current_path.match?(/\.(svg|png|jpg|jpeg|gif|ico|css|js|woff|woff2|ttf|eot)$/i) ||
      current_path.start_with?('/assets/')
  end

  def reset_tracking_if_expired(last_time, _last_path, _redirect_count)
    # Reset after 3 seconds of inactivity (was 5)
    return unless last_time && Time.current.to_i - last_time > 3

    clear_redirect_tracking
  end

  def handle_redirect_tracking(current_path, last_path, redirect_count)
    came_from_redirect = came_from_redirect?(last_path)

    if last_path == current_path && came_from_redirect
      handle_same_path_redirect(current_path, redirect_count)
    elsif last_path == current_path && !came_from_redirect
      clear_redirect_tracking # Normal navigation, reset
    elsif last_path != current_path
      clear_redirect_tracking # Different path, reset
    end

    store_current_path(current_path)
  end

  def came_from_redirect?(last_path)
    referer_path = request.referer&.split('?')&.first&.gsub(%r{^https?://[^/]+}, '')
    referer_path.present? && last_path.present? && referer_path == last_path
  end

  def handle_same_path_redirect(_current_path, redirect_count)
    redirect_count += 1
    session[:last_redirect_count] = redirect_count
    session[:last_redirect_time] = Time.current.to_i

    # Trigger after 20 rapid redirects to the same path (relaxed from 2)
    handle_redirect_loop if redirect_count >= 20
  end

  def clear_redirect_tracking
    session.delete(:last_redirect_path)
    session.delete(:last_redirect_count)
    session.delete(:last_redirect_time)
  end

  def store_current_path(current_path)
    session[:last_redirect_path] = current_path
    session[:last_redirect_time] = Time.current.to_i
  end

  def handle_redirect_loop
    # Clear the redirect tracking
    session.delete(:last_redirect_path)

    # Clear all session data
    reset_session

    # Redirect to login page to break the loop
    redirect_path = if respond_to?(:new_user_session_path)
                      new_user_session_path
                    else
                      root_path
                    end

    # rubocop:disable I18n/GetText/DecorateString
    redirect_to redirect_path, alert: 'Brak odpowiednich uprawnień do tego panelu. Zaloguj się ponownie.'
    # rubocop:enable I18n/GetText/DecorateString
  end
end
