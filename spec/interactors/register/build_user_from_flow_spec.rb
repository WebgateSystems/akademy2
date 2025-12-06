# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Register::BuildUserFromFlow do
  describe '#call' do
    let(:flow) do
      flow = Register::WizardFlow.new({})
      flow.update(:profile, {
                    'first_name' => 'John',
                    'last_name' => 'Doe',
                    'birthdate' => '1990-01-15',
                    'email' => 'john@example.com'
                  })
      flow.update(:phone, { 'phone' => '+48123456789' })
      flow.update(:pin, { 'pin' => '1234' })
      flow
    end

    it 'builds user with correct attributes' do
      result = described_class.call(flow: flow)

      expect(result).to be_success
      expect(result.user).to be_a(User)
      expect(result.user.first_name).to eq('John')
      expect(result.user.last_name).to eq('Doe')
      expect(result.user.email).to eq('john@example.com')
      expect(result.user.phone).to eq('+48123456789')
    end

    it 'sets password from pin' do
      result = described_class.call(flow: flow)

      expect(result.user.password).to eq('1234')
      expect(result.user.password_confirmation).to eq('1234')
    end

    it 'does not save the user' do
      result = described_class.call(flow: flow)

      expect(result.user).not_to be_persisted
    end
  end
end
