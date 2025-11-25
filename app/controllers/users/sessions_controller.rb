class Users::SessionsController < Devise::SessionsController
  # POST /resource/sign_in
  def create
    return handle_student_login if student_role?

    super
  end

  private

  # ============================
  #  STUDENT LOGIN
  # ============================

  def handle_student_login
    return render_student_error('Użytkownik z takim numerem nie istnieje') unless student_user
    return render_student_error('Nieprawidłowy PIN') unless valid_student_pin?

    sign_in(student_user)
    redirect_to authenticated_root_path
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
end
