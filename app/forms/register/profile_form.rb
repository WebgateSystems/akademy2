# frozen_string_literal: true

module Register
  class ProfileForm
    include ActiveModel::Model

    attr_accessor :first_name, :last_name, :birthdate, :email, :phone

    validates :first_name, presence: { message: "can't be blank" }
    validates :last_name,  presence: { message: "can't be blank" }
    validates :email,
              presence: { message: "can't be blank" },
              format: { with: URI::MailTo::EMAIL_REGEXP, message: 'is not valid' }
    validates :phone, presence: { message: "can't be blank" }

    def to_h
      {
        'first_name' => first_name,
        'last_name' => last_name,
        'birthdate' => birthdate,
        'email' => email,
        'phone' => phone
      }
    end
  end
end
