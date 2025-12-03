# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolClass, 'join_token' do
  let(:school) { create(:school) }
  let(:school_class) { create(:school_class, school: school) }

  describe '#join_token' do
    it 'returns first 3 sections of UUID (id)' do
      # UUID format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
      # join_token should be: xxxxxxxx-xxxx-xxxx
      token = school_class.join_token
      parts = token.split('-')

      expect(parts.length).to eq(3)
      expect(parts[0].length).to eq(8)
      expect(parts[1].length).to eq(4)
      expect(parts[2].length).to eq(4)
    end

    it 'matches the beginning of id (UUID)' do
      token = school_class.join_token
      expect(school_class.id.to_s).to start_with(token)
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

    it 'returns nil for invalid token' do
      found = described_class.find_by_join_token('invalid-token-here')

      expect(found).to be_nil
    end

    it 'returns nil for non-existent UUID prefix' do
      found = described_class.find_by_join_token('00000000-0000-0000')

      expect(found).to be_nil
    end
  end
end
