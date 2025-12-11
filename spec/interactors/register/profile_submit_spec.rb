# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Register::ProfileSubmit do
  describe '#call' do
    let(:flow) { Register::WizardFlow.new({}) }

    let(:valid_params) do
      ActionController::Parameters.new(
        register_profile_form: {
          first_name: 'John',
          last_name: 'Doe',
          birthdate: '1990-01-15',
          email: 'john@example.com',
          phone: '+48123456789'
        }
      )
    end

    let(:invalid_params) do
      ActionController::Parameters.new(
        register_profile_form: {
          first_name: '',
          last_name: '',
          email: 'invalid',
          phone: ''
        }
      )
    end

    context 'with valid params' do
      it 'succeeds' do
        result = described_class.call(params: valid_params, flow: flow)

        expect(result).to be_success
      end

      it 'updates flow with profile data' do
        described_class.call(params: valid_params, flow: flow)

        expect(flow['profile']).to be_present
        expect(flow['profile']['first_name']).to eq('John')
      end

      it 'sends SMS code' do
        expect(Register::SendSmsCode).to receive(:call).with(
          phone: '+48123456789',
          flow: flow
        )

        described_class.call(params: valid_params, flow: flow)
      end

      it 'sets form in context' do
        result = described_class.call(params: valid_params, flow: flow)

        expect(result.form).to be_a(Register::ProfileForm)
      end
    end

    context 'with invalid params' do
      it 'fails' do
        result = described_class.call(params: invalid_params, flow: flow)

        expect(result).to be_failure
        expect(result.message).to eq('Validation failed')
      end
    end

    context 'with birthdate_display and marketing params' do
      let(:params_with_extra_fields) do
        ActionController::Parameters.new(
          register_profile_form: {
            first_name: 'John',
            last_name: 'Doe',
            birthdate: '1990-01-15',
            birthdate_display: '15.01.1990',
            email: 'john@example.com',
            phone: '+48123456789',
            marketing: '1'
          }
        )
      end

      it 'removes birthdate_display and marketing from params' do
        result = described_class.call(params: params_with_extra_fields, flow: flow)

        expect(result).to be_success
        expect(flow['profile']['birthdate_display']).to be_nil
        expect(flow['profile']['marketing']).to be_nil
        expect(flow['profile']['birthdate']).to eq('1990-01-15')
      end
    end
  end
end
