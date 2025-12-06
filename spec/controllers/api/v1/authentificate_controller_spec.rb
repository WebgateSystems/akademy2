# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::AuthentificateController, type: :controller do
  controller(described_class) do
    def dummy
      head :ok
    end
  end

  let(:user) { build_stubbed(:user, locale: 'pl') }

  before do
    routes.draw { get 'dummy' => 'api/v1/authentificate#dummy' }
    controller.instance_variable_set(:@current_user, user)
  end

  describe '#prepare_lang' do
    it 'sets locale from current_user' do
      controller.send(:prepare_lang)
      expect(I18n.locale).to eq(:pl)
    end

    it 'falls back to :en when locale not available' do
      controller.instance_variable_set(:@current_user, build_stubbed(:user, locale: 'xx'))
      controller.send(:prepare_lang)
      expect(I18n.locale).to eq(:en)
    end
  end

  describe 'before_action authorize_access_request!' do
    it 'responds 401 without token' do
      get :dummy
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
