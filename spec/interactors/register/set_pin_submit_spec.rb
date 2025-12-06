# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Register::SetPinSubmit do
  describe '#call' do
    let(:flow) { Register::WizardFlow.new({}) }

    context 'with valid PIN' do
      let(:valid_params) { { pin_hidden: '1234' } }

      it 'succeeds' do
        result = described_class.call(params: valid_params, flow: flow)

        expect(result).to be_success
      end

      it 'stores PIN in flow' do
        described_class.call(params: valid_params, flow: flow)

        expect(flow['pin_temp']['pin']).to eq('1234')
      end

      it 'sets form in context' do
        result = described_class.call(params: valid_params, flow: flow)

        expect(result.form).to be_a(Register::PinForm)
      end
    end

    context 'with invalid PIN' do
      let(:invalid_params) { { pin_hidden: '12' } } # Too short

      it 'fails' do
        result = described_class.call(params: invalid_params, flow: flow)

        expect(result).to be_failure
        expect(result.message).to eq('PIN validation failed')
      end

      it 'sets form in context with errors' do
        result = described_class.call(params: invalid_params, flow: flow)

        expect(result.form).to be_a(Register::PinForm)
        expect(result.form.errors).not_to be_empty
      end
    end

    context 'with empty PIN' do
      let(:empty_params) { { pin_hidden: '' } }

      it 'fails' do
        result = described_class.call(params: empty_params, flow: flow)

        expect(result).to be_failure
      end
    end
  end
end
