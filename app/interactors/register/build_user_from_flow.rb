module Register
  class BuildUserFromFlow < BaseInteractor
    def call
      context.user = User.new(user_attributes)
    end

    private

    def user_attributes
      {
        first_name: profile['first_name'],
        last_name: profile['last_name'],
        birthdate: profile['birthdate'],
        email: profile['email'],
        phone: phone,
        password: pin,
        password_confirmation: pin
      }
    end

    def profile
      context.flow['profile']
    end

    def phone
      context.flow['phone']['phone']
    end

    def pin
      context.flow['pin']['pin']
    end
  end
end
