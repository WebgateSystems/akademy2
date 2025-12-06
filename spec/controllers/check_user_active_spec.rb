# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationController, 'check_user_active' do
  controller do
    def index
      render plain: 'OK'
    end
  end

  let(:user) { create(:user, confirmed_at: Time.current) }

  before do
    sign_in user
  end

  describe 'when user is active' do
    it 'allows access' do
      get :index
      expect(response).to have_http_status(:ok)
      expect(response.body).to eq('OK')
    end
  end

  describe 'when user is locked (inactive)' do
    before do
      user.update!(locked_at: Time.current)
    end

    it 'signs out the user' do
      get :index
      expect(controller.current_user).to be_nil
    end

    it 'redirects to login page' do
      get :index
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'shows alert message' do
      get :index
      expect(flash[:alert]).to include('locked')
    end
  end
end
