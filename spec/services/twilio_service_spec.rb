# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TwilioService, type: :service do
  let(:to) { '+48123456789' }
  let(:body) { 'Test SMS body' }
  let(:from_number) { '+48999888777' }

  let(:twilio_client) { instance_double(Twilio::REST::Client) }
  let(:messages) { instance_double(Twilio::REST::Api::V2010::AccountContext::MessageList) }
  # Use a string name here to avoid needing a real TwilioMessage constant
  # rubocop:disable RSpec/VerifiedDoubleReference
  let(:message) { instance_double('TwilioMessage', sid: 'SM123', status: 'sent') }
  # rubocop:enable RSpec/VerifiedDoubleReference

  before do
    # Settings stub
    allow(Settings.services.twilio).to receive_messages(
      phone_number: '+48000000000',
      account_sid: 'default_sid',
      auth_token: 'default_token'
    )

    # Logger stub
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:error)

    # Twilio client stubs
    allow(Twilio::REST::Client).to receive(:new).and_return(twilio_client)
    allow(twilio_client).to receive(:messages).and_return(messages)
    allow(messages).to receive(:create).and_return(message)
  end

  describe '.send_sms' do
    it 'delegates to the singleton instance' do
      instance = described_class.instance
      allow(instance).to receive(:send_sms).and_return({ success: true })

      result = described_class.send_sms(to: to, body: body)

      expect(instance).to have_received(:send_sms).with(to: to, body: body)
      expect(result).to eq(success: true)
    end
  end

  describe '#send_sms' do
    subject(:service) { described_class.instance }

    context 'when environment is not allowed' do
      before do
        allow(Rails.env).to receive(:in?).with(%w[production staging]).and_return(false)
      end

      it 'skips sending SMS and logs the reason' do
        result = service.send_sms(to: to, body: body)

        expect(result).to eq(success: true, skipped: true)
        expect(Rails.logger).to have_received(:info)
          .with("[Twilio] SMS skipped (env=#{Rails.env}) to #{to}: #{body}")
        expect(Twilio::REST::Client).not_to have_received(:new)
      end
    end

    context 'when environment is allowed' do
      before do
        allow(Rails.env).to receive(:in?).with(%w[production staging]).and_return(true)
      end

      it 'sends SMS with default from number when from is nil' do
        result = service.send_sms(to: '48123456789', body: body)

        expect(Twilio::REST::Client).to have_received(:new).with('default_sid', 'default_token')
        expect(messages).to have_received(:create).with(
          to: '+48123456789',
          body: body,
          from: '+48000000000'
        )
        expect(result).to eq(success: true, sid: 'SM123', status: 'sent')
      end

      it 'sends SMS with explicit from number when provided' do
        service.send_sms(to: to, body: body, from: '600-700-800')

        expect(messages).to have_received(:create).with(
          to: to,
          body: body,
          from: '+600700800'
        )
      end

      it 'uses messaging_service_sid when provided instead of from' do
        service.send_sms(to: to, body: body, messaging_service_sid: 'MG123')

        expect(messages).to have_received(:create).with(
          to: to,
          body: body,
          messaging_service_sid: 'MG123'
        )
      end

      it 'allows overriding account_sid and auth_token' do
        service.send_sms(
          to: to,
          body: body,
          account_sid: 'override_sid',
          auth_token: 'override_token'
        )

        expect(Twilio::REST::Client).to have_received(:new).with('override_sid', 'override_token')
      end

      it 'logs before and after sending SMS' do
        service.send_sms(to: to, body: body, from: from_number)

        expect(Rails.logger).to have_received(:info)
          .with("[Twilio] Sending SMS to #{to}: #{body}")
        expect(Rails.logger).to have_received(:info)
          .with('[Twilio] Sent successfully SID=SM123')
      end

      context 'when Twilio raises RestError' do
        let(:error) do
          Twilio::REST::RestError.allocate.tap do |e|
            allow(e).to receive_messages(message: 'Boom', code: 400)
          end
        end

        before do
          allow(messages).to receive(:create).and_raise(error)
        end

        it 'logs the error and returns failure hash' do
          result = service.send_sms(to: to, body: body)

          expect(Rails.logger).to have_received(:error)
            .with(/\[Twilio\] Error: Boom/)
          expect(result).to include(success: false, error: 'Boom', code: 400)
        end
      end
    end
  end
end
