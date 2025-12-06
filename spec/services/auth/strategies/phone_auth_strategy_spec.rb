# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Auth::Strategies::PhoneAuthStrategy do
  describe '#initialize' do
    it 'stores params' do
      strategy = described_class.new(phone: '+48123456789', password: 'secret')
      expect(strategy.instance_variable_get(:@params)).to eq(phone: '+48123456789', password: 'secret')
    end
  end

  describe '#user' do
    context 'when phone is blank' do
      let(:strategy) { described_class.new(phone: '', password: 'secret') }

      it 'returns nil' do
        expect(strategy.user).to be_nil
      end
    end

    context 'when phone is nil' do
      let(:strategy) { described_class.new(phone: nil, password: 'secret') }

      it 'returns nil' do
        expect(strategy.user).to be_nil
      end
    end

    context 'when user exists with phone' do
      let!(:user) { create(:user, phone: '+48123456789') }
      let(:strategy) { described_class.new(phone: '+48123456789', password: 'secret') }

      it 'returns the user' do
        expect(strategy.user).to eq(user)
      end
    end

    context 'when user does not exist with phone' do
      let(:strategy) { described_class.new(phone: '+48999888777', password: 'secret') }

      it 'returns nil' do
        expect(strategy.user).to be_nil
      end
    end

    context 'when phone has whitespace' do
      let!(:user) { create(:user, phone: '+48123456789') }
      let(:strategy) { described_class.new(phone: '  +48123456789  ', password: 'secret') }

      it 'strips whitespace and finds user' do
        expect(strategy.user).to eq(user)
      end
    end
  end

  describe '#password' do
    it 'returns password as string' do
      strategy = described_class.new(phone: '+48123456789', password: 'secret')
      expect(strategy.password).to eq('secret')
    end

    it 'handles nil password' do
      strategy = described_class.new(phone: '+48123456789', password: nil)
      expect(strategy.password).to eq('')
    end

    it 'handles numeric password' do
      strategy = described_class.new(phone: '+48123456789', password: 1234)
      expect(strategy.password).to eq('1234')
    end
  end

  describe '#valid?' do
    context 'when phone is present' do
      let(:strategy) { described_class.new(phone: '+48123456789', password: 'secret') }

      it 'returns true' do
        expect(strategy.valid?).to be true
      end
    end

    context 'when phone is blank' do
      let(:strategy) { described_class.new(phone: '', password: 'secret') }

      it 'returns false' do
        expect(strategy.valid?).to be false
      end
    end

    context 'when phone is whitespace only' do
      let(:strategy) { described_class.new(phone: '   ', password: 'secret') }

      it 'returns false' do
        expect(strategy.valid?).to be false
      end
    end

    context 'when phone is nil' do
      let(:strategy) { described_class.new(phone: nil, password: 'secret') }

      it 'returns false' do
        expect(strategy.valid?).to be false
      end
    end
  end
end
