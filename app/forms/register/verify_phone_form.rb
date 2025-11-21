# frozen_string_literal: true

module Register
  class VerifyPhoneForm
    include ActiveModel::Model

    attr_accessor :code

    validates :code, presence: true, length: { is: 4 }
  end
end
