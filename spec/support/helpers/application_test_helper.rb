module ApplicationTestHelper
  def generate_token(user)
    ::Jwt::TokenService.encode({ user_id: user.id })
  end

  def generate_invitation_token(parmas)
    ::Jwt::TokenService.encode(parmas, Time.zone.now + 1.hour)
  end
end
