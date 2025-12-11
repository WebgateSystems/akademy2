class ApplicationApiController < ActionController::API
  include HandleStatusCode
  include ApiRequestLogger
  include ActionController::Flash
  include ActionController::Cookies

  attr_reader :current_user

  private

  def authenticate!
    # JWT OR Devise
    if request.headers['Authorization'].present?
      authorize_access_request!
    else
      devise_auth
    end
  end

  def authorize_access_request!
    token = request.headers['Authorization']&.split(' ')&.last

    return not_authorized unless token

    begin
      decoded_token = ::Jwt::TokenService.decode(token)
      check_exp_token(decoded_token)
    rescue JWT::DecodeError
      not_authorized
    end
  end

  def devise_auth
    # Use Warden directly for API controllers with session support
    user = warden.authenticate(scope: :user)
    if user
      @current_user = user
    else
      not_authorized
    end
  end

  def warden
    request.env['warden']
  end

  def check_exp_token(decoded_token)
    return not_authorized unless decoded_token && decoded_token[:exp] >= Time.now.to_i

    @current_user = User.find_by(id: decoded_token[:user_id])
    not_authorized if @current_user.nil?
  end

  def not_authorized
    render json: { error: I18n.t('session.errors.not_autorized') }, status: :unauthorized
  end
end
