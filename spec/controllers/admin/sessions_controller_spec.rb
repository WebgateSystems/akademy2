# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::SessionsController, type: :controller do
  describe 'GET #new' do
    it 'returns success' do
      get :new
      expect(response).to have_http_status(:ok)
    end

    it 'renders new template' do
      get :new
      expect(response).to render_template(:new)
    end

    it 'uses admin_auth layout' do
      get :new
      expect(response).to render_template(layout: 'admin_auth')
    end
  end

  describe 'POST #create' do
    context 'with valid admin credentials' do
      let!(:admin_role) { Role.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' } }
      let(:admin) do
        user = create(:user)
        UserRole.create!(user: user, role: admin_role)
        user
      end

      it 'creates session and redirects to admin root' do
        result = double(
          success?: true,
          form: double(admin_panel_access?: true),
          access_token: 'test-token'
        )
        allow(Api::V1::Sessions::CreateSession).to receive(:call).and_return(result)

        post :create, params: { email: admin.email, password: 'Password1' }

        expect(response).to redirect_to(admin_root_path)
      end
    end

    context 'with invalid credentials' do
      it 'renders new with error' do
        result = double(
          success?: false,
          message: 'Invalid credentials'
        )
        allow(Api::V1::Sessions::CreateSession).to receive(:call).and_return(result)

        post :create, params: { email: 'wrong@example.com', password: 'wrong' }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:new)
      end
    end

    context 'with non-admin user' do
      let(:user) { create(:user) }

      it 'renders new with error' do
        result = double(
          success?: true,
          form: double(admin_panel_access?: false),
          message: nil
        )
        allow(Api::V1::Sessions::CreateSession).to receive(:call).and_return(result)

        post :create, params: { email: user.email, password: 'Password1' }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:admin_role) { Role.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' } }
    let(:admin) do
      user = create(:user)
      UserRole.create!(user: user, role: admin_role)
      user
    end

    before do
      session[:admin_id] = Jwt::TokenService.encode({ user_id: admin.id })
    end

    it 'clears session' do
      delete :destroy
      expect(session[:admin_id]).to be_nil
    end

    it 'redirects to login' do
      delete :destroy
      expect(response).to redirect_to(new_admin_session_path)
    end

    it 'logs logout event' do
      expect(EventLogger).to receive(:log_logout).with(user: admin, client: 'admin')
      delete :destroy
    end
  end
end
