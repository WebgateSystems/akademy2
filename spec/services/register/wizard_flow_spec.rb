# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Register::WizardFlow do
  let(:session) { {} }
  let(:flow) { described_class.new(session) }

  describe '#initialize' do
    it 'creates session key if not exists' do
      # Access data to trigger the ||= assignment
      flow.data
      expect(session[described_class::SESSION_KEY]).to eq({})
    end

    it 'preserves existing session data' do
      session[described_class::SESSION_KEY] = { 'existing' => 'data' }
      new_flow = described_class.new(session)
      expect(new_flow.data).to eq({ 'existing' => 'data' })
    end
  end

  describe '#data' do
    it 'returns session data' do
      expect(flow.data).to eq({})
    end
  end

  describe '#[]' do
    before do
      flow.update(:profile, { 'first_name' => 'John' })
    end

    it 'returns step data with string key' do
      expect(flow['profile']).to eq({ 'first_name' => 'John' })
    end

    it 'returns step data with symbol key' do
      expect(flow[:profile]).to eq({ 'first_name' => 'John' })
    end

    it 'returns nil for non-existent key' do
      expect(flow[:nonexistent]).to be_nil
    end
  end

  describe '#update' do
    it 'creates step data if not exists' do
      flow.update(:profile, { 'first_name' => 'John' })
      expect(flow['profile']).to eq({ 'first_name' => 'John' })
    end

    it 'merges with existing step data' do
      flow.update(:profile, { 'first_name' => 'John' })
      flow.update(:profile, { 'last_name' => 'Doe' })
      expect(flow['profile']).to eq({ 'first_name' => 'John', 'last_name' => 'Doe' })
    end
  end

  describe '#finish!' do
    before do
      flow.update(:profile, { 'first_name' => 'John' })
    end

    it 'clears session data' do
      flow.finish!
      expect(session[described_class::SESSION_KEY]).to be_nil
    end
  end

  describe '#profile_completed?' do
    it 'returns false when profile not set' do
      expect(flow.profile_completed?).to be false
    end

    it 'returns true when profile is set' do
      flow.update(:profile, { 'first_name' => 'John' })
      expect(flow.profile_completed?).to be true
    end
  end

  describe '#phone_verified?' do
    it 'returns false when phone not verified' do
      expect(flow.phone_verified?).to be false
    end

    it 'returns false when phone verified is false' do
      flow.update(:phone, { 'verified' => false })
      expect(flow.phone_verified?).to be false
    end

    it 'returns true when phone is verified' do
      flow.update(:phone, { 'verified' => true })
      expect(flow.phone_verified?).to be true
    end
  end

  describe '#pin_created?' do
    it 'returns false when pin_temp not set' do
      expect(flow.pin_created?).to be false
    end

    it 'returns true when pin_temp has pin' do
      flow.update(:pin_temp, { 'pin' => '1234' })
      expect(flow.pin_created?).to be true
    end
  end

  describe '#pin_confirmed?' do
    it 'returns false when pin not confirmed' do
      expect(flow.pin_confirmed?).to be false
    end

    it 'returns true when pin is confirmed' do
      flow.update(:pin, { 'pin' => '1234' })
      expect(flow.pin_confirmed?).to be true
    end
  end

  describe '#user_created?' do
    it 'returns false when user not created' do
      expect(flow.user_created?).to be false
    end

    it 'returns true when user_id is set' do
      flow.update(:user, { 'user_id' => 'abc-123' })
      expect(flow.user_created?).to be true
    end
  end

  describe '#can_access?' do
    context 'profile step' do
      it 'always returns true' do
        expect(flow.can_access?(:profile)).to be true
      end
    end

    context 'verify_phone step' do
      it 'returns false when profile not completed' do
        expect(flow.can_access?(:verify_phone)).to be false
      end

      it 'returns true when profile is completed' do
        flow.update(:profile, { 'first_name' => 'John' })
        expect(flow.can_access?(:verify_phone)).to be true
      end
    end

    context 'set_pin step' do
      it 'returns false when phone not verified' do
        expect(flow.can_access?(:set_pin)).to be false
      end

      it 'returns true when phone is verified' do
        flow.update(:phone, { 'verified' => true })
        expect(flow.can_access?(:set_pin)).to be true
      end
    end

    context 'set_pin_confirm step' do
      it 'returns false when phone not verified' do
        expect(flow.can_access?(:set_pin_confirm)).to be false
      end

      it 'returns false when pin not created' do
        flow.update(:phone, { 'verified' => true })
        expect(flow.can_access?(:set_pin_confirm)).to be false
      end

      it 'returns true when phone verified and pin created' do
        flow.update(:phone, { 'verified' => true })
        flow.update(:pin_temp, { 'pin' => '1234' })
        expect(flow.can_access?(:set_pin_confirm)).to be true
      end
    end

    context 'confirm_email step' do
      it 'returns false when user not created' do
        expect(flow.can_access?(:confirm_email)).to be false
      end

      it 'returns true when user is created' do
        flow.update(:user, { 'user_id' => 'abc-123' })
        expect(flow.can_access?(:confirm_email)).to be true
      end
    end

    context 'unknown step' do
      it 'returns false' do
        expect(flow.can_access?(:unknown_step)).to be false
      end
    end
  end

  describe 'SESSION_KEY constant' do
    it 'is defined' do
      expect(described_class::SESSION_KEY).to eq('register_wizard')
    end
  end
end
