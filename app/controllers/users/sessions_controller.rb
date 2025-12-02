class Users::SessionsController < Devise::SessionsController
  before_action :configure_sign_in_params, only: [:create]
  after_action :log_web_login, only: [:create], if: -> { user_signed_in? && !student_role? }

  # POST /resource/sign_in
  def create
    return handle_student_login if student_role?

    # Clear redirect loop tracking on successful login
    session.delete(:last_redirect_path) if session[:last_redirect_path]

    super
  end

  # DELETE /resource/sign_out
  def destroy
    user_to_logout = current_user
    super
    EventLogger.log_logout(user: user_to_logout, client: 'web') if user_to_logout
  end

  private

  def configure_sign_in_params
    devise_parameter_sanitizer.permit(:sign_in, keys: [:role])
  end

  # ============================
  #  STUDENT LOGIN
  # ============================

  def handle_student_login
    return render_student_error('Użytkownik z takim numerem nie istnieje') unless student_user
    return render_student_error('Nieprawidłowy PIN') unless valid_student_pin?

    # Clear redirect loop tracking on successful login
    session.delete(:last_redirect_path) if session[:last_redirect_path]

    sign_in(student_user)
    EventLogger.log_login(user: student_user, client: 'web_student')
    redirect_to public_home_path
  end

  def student_role?
    params.dig(:user, :role) == 'student'
  end

  def student_phone
    params[:phone].to_s.strip
  end

  def student_pin
    params[:password].to_s.strip
  end

  def student_user
    @student_user ||= User
                      .joins(:roles)
                      .where(roles: { key: 'student' })
                      .find_by(phone: student_phone)
  end

  def valid_student_pin?
    student_user.valid_password?(student_pin)
  end

  def render_student_error(message)
    flash.now[:alert] = message
    render :new, status: :unprocessable_entity
  end

  def log_web_login
    EventLogger.log_login(user: current_user, client: 'web') if current_user
  end
end
