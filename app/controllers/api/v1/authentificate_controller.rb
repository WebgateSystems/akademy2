module Api
  module V1
    class AuthentificateController < ApplicationApiController
      before_action :authenticate!, :prepare_lang

      private

      def prepare_lang
        lang = current_user.locale || :en
        lang = :en unless I18n.available_locales.include?(lang.to_sym)
        I18n.locale = lang
      end
    end
  end
end
