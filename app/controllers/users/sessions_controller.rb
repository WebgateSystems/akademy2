class Users::SessionsController < Devise::SessionsController
  before_action :configure_sign_in_params, only: [:create]
  after_action :log_web_login, only: [:create], if: -> { response.redirect? && user_signed_in? && !student_role? }

  # POST /resource/sign_in
  def create
    return handle_student_login if student_role?

    # Store intended destination based on role parameter (only if not already set)
    role = params.dig(:user, :role) || params[:role]
    if role.present? && session[:user_return_to].blank? && session[:return_to].blank?
      case role
      when 'student'
        session[:return_to] = public_home_path
      when 'teacher'
        session[:return_to] = dashboard_path
      when 'administration'
        session[:return_to] = management_root_path
      end
    end

    # Check permissions before allowing login
    # Get the intended destination from stored location or session
    intended_path = session[:user_return_to] || session[:return_to]

    if intended_path.present?
      permission_result = user_has_permissions_for_path?(intended_path)

      # nil means already handled (e.g., locked user)
      return if permission_result.nil?

      unless permission_result
        # User doesn't have permissions for intended path
        # Set resource for Devise form
        user_params = params.fetch(:user) { {} }.permit(:email, :password, :remember_me)
        self.resource = resource_class.new(user_params)

        # rubocop:disable I18n/GetText/DecorateString
        flash.now[:alert] = 'Brak uprawnień do tego panelu. Zaloguj się kontem z odpowiednimi uprawnieniami.'
        # rubocop:enable I18n/GetText/DecorateString
        render :new, status: :unprocessable_entity
        return
      end
    end

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

  # rubocop:disable I18n/GetText/DecorateString
  def handle_student_login
    return render_student_error('Użytkownik z takim numerem nie istnieje') unless student_user
    if student_user.inactive?
      return render_student_error('Twoje konto zostało zablokowane. Skontaktuj się z administracją szkoły.')
    end
    return render_student_error('Nieprawidłowy PIN') unless valid_student_pin?

    sign_in(student_user)
    EventLogger.log_login(user: student_user, client: 'web_student')

    # Check if there's a class token in session (from join link)
    if session[:join_class_token].present?
      token = session[:join_class_token]
      session.delete(:join_class_token) # Clean up session
      redirect_to public_home_path(token: token)
    else
      redirect_to public_home_path
    end
  end
  # rubocop:enable I18n/GetText/DecorateString

  def student_role?
    params[:role] == 'student' || params.dig(:user, :role) == 'student'
  end

  def student_phone
    params[:phone].to_s.strip.gsub(/[^\d+]/, '')
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
    # Set resource for Devise form to avoid "First argument in form cannot contain nil" error
    self.resource = resource_class.new
    flash.now[:alert] = message
    render :new, status: :unprocessable_entity
  end

  def log_web_login
    EventLogger.log_login(user: current_user, client: 'web') if current_user
  end

  def user_has_permissions_for_path?(path)
    return true if path.blank?

    # Get user from params (before login)
    email = params.dig(:user, :email)
    return false unless email

    user = User.find_by(email: email)
    return false unless user

    # Check if user is locked (inactive)
    if user.inactive?
      # Set resource for Devise form
      user_params = params.fetch(:user) { {} }.permit(:email, :password, :remember_me)
      self.resource = resource_class.new(user_params)
      # rubocop:disable I18n/GetText/DecorateString
      flash.now[:alert] = 'Twoje konto zostało zablokowane. Skontaktuj się z administratorem.'
      # rubocop:enable I18n/GetText/DecorateString
      render :new, status: :unprocessable_entity
      return nil # Signal that we've already handled the response
    end

    # Validate password first
    password = params.dig(:user, :password)
    return false unless user.valid_password?(password)

    # Check permissions for intended path
    user_roles = user.roles.pluck(:key)

    if path.start_with?('/admin')
      user_roles.include?('admin')
    elsif path.start_with?('/dashboard')
      user_roles.include?('teacher')
    elsif path.start_with?('/management')
      user_roles.include?('principal') || user_roles.include?('school_manager')
    elsif path.start_with?('/home')
      user_roles.include?('student')
    else
      # If path doesn't require specific role, allow login
      true
    end
  end
end
