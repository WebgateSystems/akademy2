# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Register flow interactors' do
  def ac_params(hash)
    ActionController::Parameters.new(hash)
  end

  before do
    twilio_client = instance_double(Twilio::REST::Client)
    messages = instance_double(Twilio::REST::Api::V2010::AccountContext::MessageList)

    allow(messages).to receive(:create).and_return(
      OpenStruct.new(sid: 'SM123', status: 'sent')
    )

    allow(twilio_client).to receive(:messages).and_return(messages)
    allow(Twilio::REST::Client).to receive(:new).and_return(twilio_client)
  end

  describe Api::V1::Register::Flows::Create do
    it 'creates a new registration flow' do
      expect do
        result = described_class.call(params: {})
        expect(result).to be_success
        expect(result.form).to be_a(RegistrationFlow)
      end.to change(RegistrationFlow, :count).by(1)
    end
  end

  describe Api::V1::Register::SendSmsCodeApi do
    let(:flow) { create(:registration_flow) }

    it 'fails when flow is missing' do
      result = described_class.call(flow: nil, phone: '+48123123123')

      expect(result).to be_failure
      expect(result.message).to include('Flow not found')
    end

    it 'updates flow with phone data and code' do
      result = described_class.call(flow:, phone: '+48123123123')

      expect(result).to be_success
      # Code is now random 4 digits, just check format
      expect(result.code).to match(/\A\d{4}\z/)
      expect(flow.reload.phone_code).to match(/\A\d{4}\z/)
      expect(flow.step).to eq('verify_phone')
      expect(flow.data['phone']['number']).to eq('+48123123123')
    end
  end

  describe Api::V1::Register::Steps::Profile do
    let(:flow) { create(:registration_flow) }
    let(:valid_params) do
      {
        flow_id: flow.id,
        profile: {
          first_name: 'Jan',
          last_name: 'Nowak',
          email: 'jan.nowak@example.com',
          birthdate: '01.01.2010',
          phone: '+48123123123'
        }
      }
    end

    it 'stores profile data and triggers sms code' do
      allow(Api::V1::Register::SendSmsCodeApi).to receive(:call)

      result = described_class.call(params: ac_params(valid_params))

      expect(result).to be_success
      expect(Api::V1::Register::SendSmsCodeApi).to have_received(:call)
      expect(flow.reload.data['profile']['first_name']).to eq('Jan')
      expect(flow.step).to eq('verify_phone')
    end

    it 'fails when form invalid' do
      invalid_params = valid_params.deep_dup
      invalid_params[:profile][:email] = 'invalid'

      result = described_class.call(params: ac_params(invalid_params))

      expect(result).to be_failure
      expect(result.errors).to be_present
    end
  end

  describe Api::V1::Register::Steps::VerifyPhone do
    let(:flow) { create(:registration_flow, phone_code: '0000', expires_at: 1.hour.from_now) }

    it 'verifies code and advances step' do
      result = described_class.call(params: ac_params(flow_id: flow.id, code: '0000'))

      expect(result).to be_success
      expect(flow.reload.phone_verified).to be(true)
      expect(flow.step).to eq('set_pin')
    end

    it 'fails when code invalid' do
      result = described_class.call(params: ac_params(flow_id: flow.id, code: '1234'))

      expect(result).to be_failure
      expect(result.status).to eq(:unprocessable_entity)
    end

    it 'fails when flow expired' do
      flow.update!(expires_at: 1.hour.ago)

      result = described_class.call(params: ac_params(flow_id: flow.id, code: '0000'))

      expect(result).to be_failure
      expect(result.status).to eq(:gone)
    end
  end

  describe Api::V1::Register::Steps::SetPin do
    let(:flow) { create(:registration_flow, expires_at: 1.hour.from_now) }

    it 'saves temporary pin when valid' do
      result = described_class.call(params: ac_params(flow_id: flow.id, pin: '1234'))

      expect(result).to be_success
      expect(flow.reload.pin_temp).to eq('1234')
      expect(flow.step).to eq('confirm_pin')
    end

    it 'fails with invalid pin' do
      result = described_class.call(params: ac_params(flow_id: flow.id, pin: '12'))

      expect(result).to be_failure
      expect(result.status).to eq(:unprocessable_entity)
    end
  end

  describe Api::V1::Register::Steps::ConfirmPin do
    let(:flow) { create(:registration_flow, pin_temp: '1234') }
    let(:finish_result) do
      double('FinishResult', success?: true, form: build(:user), access_token: 'jwt-token')
    end

    before do
      allow(Api::V1::Register::Steps::Finish).to receive(:call).and_return(finish_result)
    end

    it 'delegates to finish step when pins match' do
      result = described_class.call(params: ac_params(flow_id: flow.id, pin: '1234'))

      expect(result).to be_success
      expect(result.form).to eq(finish_result.form)
      expect(Api::V1::Register::Steps::Finish).to have_received(:call)
    end

    it 'fails when pins mismatch' do
      result = described_class.call(params: ac_params(flow_id: flow.id, pin: '9999'))

      expect(result).to be_failure
      expect(result.status).to eq(:unprocessable_entity)
      expect(Api::V1::Register::Steps::Finish).not_to have_received(:call)
    end
  end

  describe Api::V1::Register::Steps::Finish do
    let(:flow) do
      RegistrationFlow.create!(
        data: {
          'profile' => {
            'first_name' => 'Jan',
            'last_name' => 'Kowalski',
            'birthdate' => '01.01.2010',
            'email' => 'jan.finish@example.com',
            'phone' => '+48123123123'
          },
          'phone' => { 'number' => '+48123123123' }
        },
        pin_temp: '1234'
      )
    end
    let(:session_double) { double('SessionResult', access_token: 'jwt-token') }

    before do
      allow(Api::V1::Sessions::CreateSession).to receive(:call).and_return(session_double)
    end

    it 'creates the user, destroys flow, and returns token' do
      result = described_class.call(params: { flow_id: flow.id })

      expect(result).to be_success
      expect(result.form).to be_a(User)
      expect(result.access_token).to eq('jwt-token')
      expect(RegistrationFlow.find_by(id: flow.id)).to be_nil
    end

    it 'fails when user cannot be saved' do
      create(:user, email: 'jan.finish@example.com')

      result = described_class.call(params: { flow_id: flow.id })

      expect(result).to be_failure
      expect(result.status).to eq(:unprocessable_entity)
    end
  end
end
