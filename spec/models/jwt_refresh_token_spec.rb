# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JwtRefreshToken, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'columns' do
    it { is_expected.to have_db_column(:exp) }
    it { is_expected.to have_db_column(:revoked_at) }
    it { is_expected.to have_db_column(:token_digest) }
    it { is_expected.to have_db_column(:user_id) }
  end

  describe 'factory' do
    let(:user) { create(:user) }

    it 'creates valid token' do
      token = described_class.create!(
        user: user,
        token_digest: SecureRandom.hex(32),
        exp: 1.week.from_now
      )
      expect(token).to be_valid
      expect(token.user).to eq(user)
    end
  end
end
