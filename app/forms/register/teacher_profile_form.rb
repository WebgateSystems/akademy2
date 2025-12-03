# frozen_string_literal: true

module Register
  class TeacherProfileForm
    include ActiveModel::Model

    attr_accessor :first_name, :last_name, :email, :phone, :password, :password_confirmation

    validates :first_name, presence: { message: "can't be blank" }
    validates :last_name,  presence: { message: "can't be blank" }
    validates :email,
              presence: { message: "can't be blank" },
              format: { with: URI::MailTo::EMAIL_REGEXP, message: 'is not valid' }
    validates :phone, presence: { message: "can't be blank" }
    validates :password, presence: { message: "can't be blank" },
                         length: { minimum: 6, message: 'is too short (minimum is 6 characters)' }
    validates :password_confirmation, presence: { message: "can't be blank" }
    validate :password_match

    def to_h
      {
        'first_name' => first_name,
        'last_name' => last_name,
        'email' => email,
        'phone' => phone,
        'password' => password,
        'password_confirmation' => password_confirmation
      }
    end

    private

    def password_match
      return if password.blank? || password_confirmation.blank?

      return if password == password_confirmation

      errors.add(:password_confirmation, "doesn't match Password")
    end
  end
end
