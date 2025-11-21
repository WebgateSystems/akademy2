# frozen_string_literal: true

module Register
  class ProfileForm
    include ActiveModel::Model

    attr_accessor :first_name, :last_name, :birthdate, :email, :phone, :marketing

    validates :first_name, :last_name, :email, :phone, presence: true
    validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }

    def to_h
      {
        "first_name" => first_name,
        "last_name"  => last_name,
        "birthdate"  => birthdate,
        "email"      => email,
        "phone"      => phone,
        "marketing"  => marketing == "1"
      }
    end
  end
end
