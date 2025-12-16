# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Users::VerifyPhoneCode do
  let(:user) { create(:user, metadata: metadata) }
  let(:submitted_code) { '123456' }
  let(:service) { described_class.new(user, submitted_code) }

  describe '#call' do
    context 'when there was no verification request' do
      let(:metadata) { {} }

      it 'returns :no_request' do
        expect(service.call).to eq(:no_request)
      end
    end

    context 'when verification request exists' do
      let(:sent_at) { Time.current.iso8601 }
      let(:base_metadata) do
        {
          'phone_verification' => {
            'code' => '123456',
            'sent_at' => sent_at
          }
        }
      end

      context 'when the request is expired' do
        let(:metadata) do
          base_metadata.deep_merge(
            'phone_verification' => { 'sent_at' => 10.minutes.ago.iso8601 }
          )
        end

        it 'returns :expired' do
          expect(service.call).to eq(:expired)
        end
      end

      context 'when the code is incorrect' do
        let(:metadata) { base_metadata }
        let(:submitted_code) { '000000' }

        it 'returns :invalid and increments attempts counter' do
          allow(user).to receive(:update!).and_call_original

          result = service.call

          expect(result).to eq(:invalid)
          expect(user).to have_received(:update!) do |attrs|
            data = attrs[:metadata]['phone_verification']
            expect(data['attempts']).to eq(1)
          end
        end

        it 'increments attempts from existing value' do
          metadata_with_attempts = base_metadata.deep_merge(
            'phone_verification' => { 'attempts' => 2 }
          )
          user_with_attempts = create(:user, metadata: metadata_with_attempts)
          service_with_attempts = described_class.new(user_with_attempts, '000000')

          expect do
            service_with_attempts.call
          end.to change {
            user_with_attempts.reload.metadata['phone_verification']['attempts']
          }.from(2).to(3)
        end
      end

      context 'when the code is correct' do
        let(:metadata) { base_metadata }

        it 'returns :ok and marks phone as verified' do
          expect do
            expect(service.call).to eq(:ok)
          end.to change { user.reload.metadata['phone_verified'] }.from(nil).to(true)
        end

        it 'clears phone_verification data' do
          service.call
          expect(user.reload.metadata['phone_verification']).to be_nil
        end
      end
    end
  end
end
