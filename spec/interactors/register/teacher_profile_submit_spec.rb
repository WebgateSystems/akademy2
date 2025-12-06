# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Register::TeacherProfileSubmit do
  describe '#call' do
    let(:flow) { Register::WizardFlow.new({}) }

    let(:valid_params) do
      ActionController::Parameters.new(
        register_teacher_profile_form: {
          first_name: 'John',
          last_name: 'Doe',
          email: 'john@example.com',
          phone: '+48123456789',
          password: 'Password1!',
          password_confirmation: 'Password1!',
          join_token: 'abc-123-token'
        }
      )
    end

    let(:valid_params_alt_key) do
      ActionController::Parameters.new(
        register_profile_form: {
          first_name: 'Jane',
          last_name: 'Doe',
          email: 'jane@example.com',
          phone: '+48987654321',
          password: 'Password1!',
          password_confirmation: 'Password1!'
        }
      )
    end

    let(:invalid_params) do
      ActionController::Parameters.new(
        register_teacher_profile_form: {
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

      it 'stores join_token in school data' do
        described_class.call(params: valid_params, flow: flow)

        expect(flow['school']['join_token']).to eq('abc-123-token')
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

        expect(result.form).to be_a(Register::TeacherProfileForm)
      end
    end

    context 'with alternative param key' do
      it 'succeeds with register_profile_form key' do
        result = described_class.call(params: valid_params_alt_key, flow: flow)

        expect(result).to be_success
        expect(flow['profile']['first_name']).to eq('Jane')
      end
    end

    context 'with invalid params' do
      it 'fails' do
        result = described_class.call(params: invalid_params, flow: flow)

        expect(result).to be_failure
        expect(result.message).to eq('Validation failed')
      end

      it 'sets form with errors' do
        result = described_class.call(params: invalid_params, flow: flow)

        expect(result.form.errors).not_to be_empty
      end
    end
  end
end
