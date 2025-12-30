class SidekiqAuthMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    session = env['rack.session']
    token = session[:admin_id]

    return redirect_to_login unless admin?(token)

    @app.call(env)
  end

  private

  def admin?(token)
    decoded_token = ::Jwt::TokenService.decode(token)
    check_exp_token(decoded_token)
  rescue JWT::DecodeError
    false
  end

  def check_exp_token(decoded_token)
    return false unless decoded_token && decoded_token[:exp] >= Time.now.to_i

    user = User.find_by(id: decoded_token[:user_id])
    user&.admin? || user&.manager?
  end

  def redirect_to_login
    [302, { 'Location' => '/admin/sign_in', 'Content-Type' => 'text/html' }, []]
  end
end
