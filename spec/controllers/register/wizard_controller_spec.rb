# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Register::WizardController, type: :controller do
  describe 'GET #profile' do
    it 'returns success' do
      get :profile
      expect(response).to have_http_status(:ok)
    end

    it 'renders profile template' do
      get :profile
      expect(response).to render_template(:profile)
    end

    it 'assigns form' do
      get :profile
      expect(assigns(:form)).to be_a(Register::ProfileForm)
    end
  end

  describe 'POST #profile_submit' do
    context 'with valid params' do
      let(:valid_params) do
        {
          register_profile_form: {
            first_name: 'John',
            last_name: 'Doe',
            birthdate: '1990-01-15',
            email: 'john@example.com',
            phone: '+48123456789'
          }
        }
      end

      it 'redirects to verify_phone' do
        post :profile_submit, params: valid_params
        expect(response).to redirect_to(register_verify_phone_path)
      end
    end

    context 'with invalid params' do
      let(:invalid_params) do
        {
          register_profile_form: {
            first_name: '',
            last_name: ''
          }
        }
      end

      it 'renders profile with errors' do
        post :profile_submit, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:profile)
      end
    end
  end

  describe 'GET #verify_phone' do
    before do
      # Setup flow to allow access
      session['register_wizard'] = {
        'profile' => { 'first_name' => 'John', 'phone' => '+48123456789' },
        'phone' => { 'phone' => '+48123456789' }
      }
    end

    it 'returns success' do
      get :verify_phone
      expect(response).to have_http_status(:ok)
    end

    it 'assigns form' do
      get :verify_phone
      expect(assigns(:form)).to be_a(Register::VerifyPhoneForm)
    end
  end

  describe 'GET #verify_phone without profile' do
    it 'redirects to profile' do
      get :verify_phone
      expect(response).to redirect_to(register_profile_path)
    end
  end

  describe 'GET #set_pin' do
    before do
      session['register_wizard'] = {
        'profile' => { 'first_name' => 'John' },
        'phone' => { 'verified' => true }
      }
    end

    it 'returns success' do
      get :set_pin
      expect(response).to have_http_status(:ok)
    end

    it 'assigns form' do
      get :set_pin
      expect(assigns(:form)).to be_a(Register::PinForm)
    end
  end

  describe 'GET #set_pin without verified phone' do
    before do
      session['register_wizard'] = {
        'profile' => { 'first_name' => 'John' },
        'phone' => { 'verified' => false }
      }
    end

    it 'redirects to profile' do
      get :set_pin
      expect(response).to redirect_to(register_profile_path)
    end
  end

  describe 'GET #set_pin_confirm' do
    before do
      session['register_wizard'] = {
        'profile' => { 'first_name' => 'John' },
        'phone' => { 'verified' => true },
        'pin_temp' => { 'pin' => '1234' }
      }
    end

    it 'returns success' do
      get :set_pin_confirm
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET #teacher' do
    it 'returns success' do
      get :teacher
      expect(response).to have_http_status(:ok)
    end

    it 'assigns form' do
      get :teacher
      expect(assigns(:form)).to be_a(Register::TeacherProfileForm)
    end

    it 'sets registration_type in flow' do
      get :teacher
      expect(session['register_wizard']['registration_type']).to eq('teacher')
    end

    context 'with join_token' do
      let(:school) { create(:school, join_token: 'test-token') }

      it 'finds school and assigns to @school' do
        get :teacher, params: { join_token: school.join_token }
        expect(assigns(:school)).to eq(school)
      end
    end
  end

  describe 'POST #verify_phone_submit' do
    before do
      session['register_wizard'] = {
        'profile' => { 'first_name' => 'John', 'phone' => '+48123456789' },
        'phone' => { 'phone' => '+48123456789', 'sms_code' => '1234', 'verified' => false }
      }
    end

    context 'with valid code' do
      it 'redirects to set_pin' do
        post :verify_phone_submit, params: { code1: '1', code2: '2', code3: '3', code4: '4' }
        expect(response).to redirect_to(register_set_pin_path)
      end
    end

    context 'with invalid code' do
      it 'renders verify_phone with error' do
        post :verify_phone_submit, params: { code1: '9', code2: '9', code3: '9', code4: '9' }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:verify_phone)
      end
    end
  end

  describe 'POST #set_pin_submit' do
    before do
      session['register_wizard'] = {
        'profile' => { 'first_name' => 'John' },
        'phone' => { 'verified' => true }
      }
    end

    context 'with valid PIN' do
      it 'redirects to set_pin_confirm' do
        post :set_pin_submit, params: { pin_hidden: '1234' }
        expect(response).to redirect_to(register_set_pin_confirm_path)
      end
    end

    context 'with invalid PIN' do
      it 'renders set_pin with errors' do
        post :set_pin_submit, params: { pin_hidden: '12' }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:set_pin)
      end
    end
  end

  describe 'POST #set_pin_confirm_submit' do
    before do
      session['register_wizard'] = {
        'profile' => {
          'first_name' => 'John',
          'last_name' => 'Doe',
          'email' => 'john@example.com',
          'phone' => '+48123456789'
        },
        'phone' => { 'phone' => '+48123456789', 'verified' => true },
        'pin_temp' => { 'pin' => '1234' }
      }
    end

    context 'with matching PIN' do
      it 'creates user and redirects to confirm_email' do
        post :set_pin_confirm_submit, params: { pin_hidden: '1234' }
        expect(response).to redirect_to(register_confirm_email_path)
      end
    end

    context 'with non-matching PIN' do
      it 'renders set_pin_confirm with error' do
        post :set_pin_confirm_submit, params: { pin_hidden: '4321' }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:set_pin_confirm)
      end
    end
  end

  describe 'GET #confirm_email' do
    before do
      session['register_wizard'] = {
        'profile' => { 'first_name' => 'John', 'email' => 'john@example.com' },
        'user' => { 'user_id' => SecureRandom.uuid }
      }
    end

    it 'returns success' do
      get :confirm_email
      expect(response).to have_http_status(:ok)
    end

    it 'renders confirm_email template' do
      get :confirm_email
      expect(response).to render_template(:confirm_email)
    end
  end

  describe 'GET #confirm_email without user_id' do
    it 'redirects to profile' do
      get :confirm_email
      expect(response).to redirect_to(register_profile_path)
    end
  end
end
