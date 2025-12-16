# frozen_string_literal: true

RSpec.describe Users::SendSmsCode do
  describe '#call' do
    let(:phone) { '+48123456789' }
    let(:result) { described_class.call(phone: phone) }

    before do
      allow(TwilioService).to receive(:send_sms)
      allow(Rails.logger).to receive(:info)
    end

    it 'succeeds' do
      expect(result).to be_success
    end

    it 'generates a 4-digit code' do
      expect(result.code).to match(/^\d{4}$/)
    end

    it 'sets code in context' do
      expect(result.code).to be_present
      expect(result.code.length).to eq(4)
    end

    it 'logs verification code' do
      result

      expect(Rails.logger).to have_received(:info)
        .with(/\[SMS\] Verification code for #{Regexp.escape(phone)}: \d{4}/)
    end

    it 'sends SMS via TwilioService' do
      result

      expect(TwilioService).to have_received(:send_sms) do |args|
        expect(args[:to]).to eq(phone)
        expect(args[:body]).to match(/Your verification code: \d{4}/)
      end
    end

    it 'includes the generated code in SMS body' do
      code = result.code

      expect(TwilioService).to have_received(:send_sms) do |args|
        expect(args[:body]).to include(code)
      end
    end

    context 'with different phone numbers' do
      let(:phone) { '+48999888777' }

      it 'sends SMS to the correct phone number' do
        result

        expect(TwilioService).to have_received(:send_sms) do |args|
          expect(args[:to]).to eq(phone)
        end
      end
    end
  end
end
