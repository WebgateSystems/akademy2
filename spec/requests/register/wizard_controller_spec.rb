require 'rails_helper'

RSpec.describe Register::WizardController, type: :request do
  let(:session_store) { {} }

  let(:flow_key) { Register::WizardFlow::SESSION_KEY }

  before do
    allow_any_instance_of(Register::WizardController)
      .to receive(:session).and_return(session_store)
  end

  # ======================================================
  # STEP 1: PROFILE
  # ======================================================

  describe 'STEP 1: PROFILE' do
    it 'renders profile' do
      get register_profile_path
      expect(response).to have_http_status(:ok)
    end

    it 'submit success → redirect to verify_phone' do
      allow(Register::ProfileSubmit).to receive(:call).and_return(
        double(success?: true, form: ::Register::ProfileForm.new({}))
      )

      post register_profile_path, params: {}

      expect(response).to redirect_to(register_verify_phone_path)
    end

    it 'submit fail → renders form with errors' do
      allow(Register::ProfileSubmit).to receive(:call).and_return(
        double(success?: false, form: ::Register::ProfileForm.new({ first_name: '' }))
      )

      post register_profile_path, params: {}

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  # ======================================================
  # STEP 2: VERIFY PHONE
  # ======================================================

  describe 'STEP 2: VERIFY PHONE' do
    before do
      session_store[flow_key] = {
        'profile' => { 'first_name' => 'John' },
        'phone' => { 'phone' => '+48123123123' }
      }
    end

    it 'renders verify_phone' do
      get register_verify_phone_path
      expect(response).to have_http_status(:ok)
    end

    it 'submit success → redirect to set_pin' do
      allow(Register::VerifyPhoneSubmit).to receive(:call).and_return(
        double(success?: true, form: ::Register::VerifyPhoneForm.new, phone: '+48', error: nil)
      )

      post register_verify_phone_path

      expect(response).to redirect_to(register_set_pin_path)
    end

    it 'submit fail → re-render verify_phone' do
      allow(Register::VerifyPhoneSubmit).to receive(:call).and_return(
        double(success?: false, form: ::Register::VerifyPhoneForm.new, phone: '+48', error: 'Invalid code')
      )

      post register_verify_phone_path

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include('Invalid code')
    end
  end

  # ======================================================
  # RESEND CODE
  # ======================================================

  describe 'RESEND CODE' do
    before do
      session_store[flow_key] = {
        'profile' => { 'first_name' => 'John' },
        'phone' => { 'phone' => '+48123123123' }
      }
    end

    it 'calls SendSmsCode with correct phone and returns ok: true' do
      expect(Register::SendSmsCode).to receive(:call).with(
        phone: '+48123123123',
        flow: an_instance_of(Register::WizardFlow)
      )

      get '/register/resend-code' # нет helper, поэтому прямой путь

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq({ 'ok' => true })
    end

    it 'handles missing phone gracefully' do
      session_store[flow_key] = {
        'profile' => { 'first_name' => 'John' },
        'phone' => {} # phone missing
      }

      expect(Register::SendSmsCode).to receive(:call).with(
        phone: nil, # важно
        flow: an_instance_of(Register::WizardFlow)
      )

      get '/register/resend-code'

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq({ 'ok' => true })
    end
  end

  # ======================================================
  # STEP 3: SET PIN
  # ======================================================

  describe 'STEP 3: set_pin' do
    before do
      session_store[flow_key] = {
        'profile' => { 'first_name' => 'John' },
        'phone' => { 'verified' => true }
      }
    end

    it 'renders set_pin' do
      get register_set_pin_path
      expect(response).to have_http_status(:ok)
    end

    it 'success → redirect to set_pin_confirm' do
      allow(Register::SetPinSubmit).to receive(:call).and_return(
        double(success?: true, form: ::Register::PinForm.new)
      )

      post register_set_pin_path

      expect(response).to redirect_to(register_set_pin_confirm_path)
    end

    it 'fail → re-render' do
      allow(Register::SetPinSubmit).to receive(:call).and_return(
        double(success?: false, form: ::Register::PinForm.new)
      )

      post register_set_pin_path

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  # ======================================================
  # STEP 4: SET PIN CONFIRM
  # ======================================================

  describe 'STEP 4: set_pin_confirm' do
    before do
      session_store[flow_key] = {
        'profile' => { 'first_name' => 'John' },
        'phone' => { 'verified' => true },
        'pin_temp' => { 'pin' => '1111' }
      }
    end

    it 'renders step' do
      get register_set_pin_confirm_path
      expect(response).to have_http_status(:ok)
    end

    it 'success → redirect to confirm_email' do
      allow(Register::SetPinConfirmSubmit).to receive(:call).and_return(
        double(success?: true, form: ::Register::PinForm.new, message: nil, redirect_path: nil)
      )

      post register_set_pin_confirm_path

      expect(response).to redirect_to(register_confirm_email_path)
    end

    it 'fail → re-render' do
      allow(Register::SetPinConfirmSubmit).to receive(:call).and_return(
        double(success?: false, form: ::Register::PinForm.new, message: 'Pins do not match', redirect_path: nil)
      )

      post register_set_pin_confirm_path

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include('Pins do not match')
    end
  end

  # ======================================================
  # STEP 5: CONFIRM EMAIL
  # ======================================================

  describe 'STEP 5: confirm_email' do
    let(:user) { create(:user) }

    before do
      session_store[flow_key] = {
        'user' => { 'user_id' => user.id }
      }
    end

    it 'renders email confirmation' do
      get register_confirm_email_path

      expect(response).to have_http_status(:ok)
      expect(assigns(:user)).to eq(user)
    end

    it 'redirects to profile if user not created' do
      session_store[flow_key] = {}

      get register_confirm_email_path

      expect(response).to redirect_to(register_profile_path)
    end
  end
end
