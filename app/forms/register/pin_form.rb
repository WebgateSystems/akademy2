# frozen_string_literal: true

module Register
  class PinForm
    include ActiveModel::Model

    attr_accessor :pin

    validates :pin, presence: true, length: { is: 4 }
  end
end
