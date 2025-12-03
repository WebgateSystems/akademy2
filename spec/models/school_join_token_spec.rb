# frozen_string_literal: true

require 'rails_helper'

RSpec.describe School, 'join_token' do
  let(:school) { create(:school) }

  describe '#join_token' do
    it 'has format xxxx-xxxx-xxxxxxxxxxxx (last 3 segments of UUID)' do
      token = school.join_token
      parts = token.split('-')

      expect(parts.length).to eq(3)
      expect(parts[0].length).to eq(4)
      expect(parts[1].length).to eq(4)
      expect(parts[2].length).to eq(12)
    end

    it 'matches the expected pattern' do
      expect(school.join_token).to match(/\A[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}\z/)
    end
  end

  describe '.find_by_join_token' do
    it 'finds school by token' do
      token = school.join_token
      found = described_class.find_by_join_token(token)

      expect(found).to eq(school)
    end

    it 'extracts token from URL' do
      url = "http://localhost:3000/join/school/#{school.join_token}"
      found = described_class.find_by_join_token(url)

      expect(found).to eq(school)
    end

    it 'returns nil for invalid token format' do
      found = described_class.find_by_join_token('invalid-token-here')

      expect(found).to be_nil
    end

    it 'returns nil for non-existent token' do
      found = described_class.find_by_join_token('0000-0000-000000000000')

      expect(found).to be_nil
    end

    it 'returns nil for class token format (wrong format)' do
      # Class tokens have format xxxxxxxx-xxxx-xxxx
      found = described_class.find_by_join_token('00000000-0000-0000')

      expect(found).to be_nil
    end
  end

  describe 'token generation' do
    it 'auto-generates join_token on create' do
      new_school = described_class.create!(name: 'Test School', city: 'Warsaw', country: 'PL')
      expect(new_school.join_token).to be_present
      expect(new_school.join_token).to match(/\A[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}\z/)
    end

    it 'does not overwrite existing join_token' do
      custom_token = 'abcd-ef12-345678901234'
      new_school = described_class.create!(
        name: 'Test School',
        city: 'Warsaw',
        country: 'PL',
        join_token: custom_token
      )
      expect(new_school.join_token).to eq(custom_token)
    end
  end
end
