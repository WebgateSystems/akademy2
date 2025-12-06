# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Register::VerifyPhoneSubmit do
  describe '#call' do
    let(:flow) do
      flow = Register::WizardFlow.new({})
      flow.update(:profile, { 'phone' => '+48123456789' })
      flow.update(:phone, { 'sms_code' => '1234', 'verified' => false })
      flow
    end

    context 'with valid code' do
      let(:valid_params) do
        { code1: '1', code2: '2', code3: '3', code4: '4' }
      end

      it 'succeeds' do
        result = described_class.call(params: valid_params, flow: flow)

        expect(result).to be_success
      end

      it 'marks phone as verified' do
        described_class.call(params: valid_params, flow: flow)

        expect(flow['phone']['verified']).to be true
      end

      it 'sets form in context' do
        result = described_class.call(params: valid_params, flow: flow)

        expect(result.form).to be_a(Register::VerifyPhoneForm)
      end
    end

    context 'with invalid code' do
      let(:invalid_params) do
        { code1: '9', code2: '9', code3: '9', code4: '9' }
      end

      it 'fails' do
        result = described_class.call(params: invalid_params, flow: flow)

        expect(result).to be_failure
        expect(result.message).to eq('Wrong Code')
      end

      it 'sets error in context' do
        result = described_class.call(params: invalid_params, flow: flow)

        expect(result.error).to eq('Wrong Code')
      end

      it 'sets phone in context' do
        result = described_class.call(params: invalid_params, flow: flow)

        expect(result.phone).to eq('+48123456789')
      end
    end
  end
end
