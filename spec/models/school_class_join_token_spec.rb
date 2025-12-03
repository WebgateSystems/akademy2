# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolClass, 'join_token' do
  let(:school) { create(:school) }
  let(:school_class) { create(:school_class, school: school) }

  describe '#join_token' do
    it 'has format xxxxxxxx-xxxx-xxxx (first 3 segments of UUID)' do
      token = school_class.join_token
      parts = token.split('-')

      expect(parts.length).to eq(3)
      expect(parts[0].length).to eq(8)
      expect(parts[1].length).to eq(4)
      expect(parts[2].length).to eq(4)
    end

    it 'matches the expected pattern' do
      expect(school_class.join_token).to match(/\A[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}\z/)
    end
  end

  describe '.find_by_join_token' do
    it 'finds class by token' do
      token = school_class.join_token
      found = described_class.find_by_join_token(token)

      expect(found).to eq(school_class)
    end

    it 'extracts token from URL' do
      url = "http://localhost:3000/join/class/#{school_class.join_token}"
      found = described_class.find_by_join_token(url)

      expect(found).to eq(school_class)
    end

    it 'returns nil for invalid token format' do
      found = described_class.find_by_join_token('invalid-token-here')

      expect(found).to be_nil
    end

    it 'returns nil for non-existent token' do
      found = described_class.find_by_join_token('00000000-0000-0000')

      expect(found).to be_nil
    end

    it 'returns nil for school token format (wrong format)' do
      # School tokens have format xxxx-xxxx-xxxxxxxxxxxx
      found = described_class.find_by_join_token('0000-0000-000000000000')

      expect(found).to be_nil
    end
  end

  describe 'token generation' do
    it 'auto-generates join_token on create' do
      new_class = described_class.create!(school: school, name: 'Test', year: '2024/2025', qr_token: SecureRandom.uuid)
      expect(new_class.join_token).to be_present
      expect(new_class.join_token).to match(/\A[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}\z/)
    end

    it 'does not overwrite existing join_token' do
      custom_token = 'abcd1234-ef56-7890'
      new_class = described_class.create!(
        school: school,
        name: 'Test',
        year: '2024/2025',
        qr_token: SecureRandom.uuid,
        join_token: custom_token
      )
      expect(new_class.join_token).to eq(custom_token)
    end
  end
end
