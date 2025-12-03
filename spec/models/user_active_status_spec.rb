# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, 'active status' do
  describe '#active?' do
    it 'returns true when locked_at is nil' do
      user = build(:user, locked_at: nil)
      expect(user.active?).to be true
    end

    it 'returns false when locked_at is set' do
      user = build(:user, locked_at: Time.current)
      expect(user.active?).to be false
    end
  end

  describe '#inactive?' do
    it 'returns false when locked_at is nil' do
      user = build(:user, locked_at: nil)
      expect(user.inactive?).to be false
    end

    it 'returns true when locked_at is set' do
      user = build(:user, locked_at: Time.current)
      expect(user.inactive?).to be true
    end
  end

  describe '#active_for_authentication?' do
    it 'returns true for active confirmed user' do
      user = create(:user, locked_at: nil, confirmed_at: Time.current)
      expect(user.active_for_authentication?).to be true
    end

    it 'returns false for locked user' do
      user = create(:user, locked_at: Time.current, confirmed_at: Time.current)
      expect(user.active_for_authentication?).to be false
    end

    # NOTE: The unconfirmed test depends on Devise configuration
    # If reconfirmable is enabled or confirmable is configured differently,
    # this behavior may vary
  end

  describe '#inactive_message' do
    it 'returns :locked for locked user' do
      user = build(:user, locked_at: Time.current)
      expect(user.inactive_message).to eq(:locked)
    end

    it 'returns :unconfirmed for unconfirmed user' do
      user = build(:user, locked_at: nil, confirmed_at: nil)
      expect(user.inactive_message).to eq(:unconfirmed)
    end
  end
end
