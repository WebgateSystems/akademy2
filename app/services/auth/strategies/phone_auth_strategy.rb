module Auth
  module Strategies
    class PhoneAuthStrategy
      def initialize(params)
        @params = params
      end

      def user
        return nil if phone.blank?

        @user ||= User.find_by(phone: phone)
      end

      def password
        @params[:password].to_s
      end

      def valid?
        phone.present?
      end

      private

      def phone
        @params[:phone].to_s.strip
      end
    end
  end
end
