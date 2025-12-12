# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Register::SendSmsCode do
  describe '#call' do
    let(:flow) { Register::WizardFlow.new({}) }
    let(:phone) { '+48123456789' }

    it 'generates 4-digit code' do
      result = described_class.call(phone: phone, flow: flow)

      expect(result).to be_success
      expect(result.code).to match(/^\d{4}$/)
    end

    it 'stores code in flow' do
      result = described_class.call(phone: phone, flow: flow)

      expect(flow['phone']['sms_code']).to eq(result.code)
    end

    it 'stores phone in flow' do
      described_class.call(phone: phone, flow: flow)

      expect(flow['phone']['phone']).to eq(phone)
    end

    it 'sets verified to false' do
      described_class.call(phone: phone, flow: flow)

      expect(flow['phone']['verified']).to be false
    end

    it 'logs verification code' do
      allow(Rails.logger).to receive(:info)

      described_class.call(phone: phone, flow: flow)

      expect(Rails.logger).to have_received(:info)
        .with(/verification code/i)
        .at_least(:once)
    end
  end
end
