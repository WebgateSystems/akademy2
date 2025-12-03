# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe '#display_phone' do
    context 'when phone is in phone column' do
      it 'returns phone from phone column' do
        user = build(:user, phone: '+48123123123', metadata: nil)
        expect(user.display_phone).to eq('+48123123123')
      end

      it 'prefers phone column over metadata phone' do
        user = build(:user, phone: '+48123123123', metadata: { 'phone' => '+48987654321' })
        expect(user.display_phone).to eq('+48123123123')
      end

      it 'returns phone from phone column when metadata has no phone' do
        user = build(:user, phone: '+48123123123', metadata: { 'other_key' => 'value' })
        expect(user.display_phone).to eq('+48123123123')
      end
    end

    context 'when phone is in metadata' do
      it 'returns phone from metadata when phone column is nil' do
        user = build(:user, phone: nil, metadata: { 'phone' => '+48123123123' })
        expect(user.display_phone).to eq('+48123123123')
      end

      it 'returns phone from metadata when phone column is empty string' do
        user = build(:user, phone: '', metadata: { 'phone' => '+48123123123' })
        expect(user.display_phone).to eq('+48123123123')
      end
    end

    context 'when phone is missing' do
      it 'returns nil when both phone and metadata phone are missing' do
        user = build(:user, phone: nil, metadata: nil)
        expect(user.display_phone).to be_nil
      end

      it 'returns nil when phone is nil and metadata has no phone key' do
        user = build(:user, phone: nil, metadata: { 'other_key' => 'value' })
        expect(user.display_phone).to be_nil
      end
    end
  end
end
