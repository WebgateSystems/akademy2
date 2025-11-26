module Auth
  module Strategies
    class EmailAuthStrategy
      def initialize(params)
        @params = params
      end

      def user
        return nil if email.blank?

        @user ||= User.find_by(email: email.downcase)
      end

      def password
        @params[:password].to_s
      end

      def valid?
        email.present?
      end

      private

      def email
        @params[:email]
      end
    end
  end
end
