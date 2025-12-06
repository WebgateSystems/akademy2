# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NotificationRead, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    let(:user) { create(:user) }
    let(:notification) { create(:notification, school: user.school) }

    it 'validates presence of notification_id' do
      record = described_class.new(user: user, notification_id: nil)
      expect(record).not_to be_valid
      expect(record.errors[:notification_id]).to include("can't be blank")
    end

    it 'validates uniqueness of notification_id scoped to user_id' do
      described_class.create!(user: user, notification_id: notification.id)
      duplicate = described_class.new(user: user, notification_id: notification.id)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to include('Notification already marked as read')
    end

    it 'allows same notification for different users' do
      other_user = create(:user)
      described_class.create!(user: user, notification_id: notification.id)
      record = described_class.new(user: other_user, notification_id: notification.id)
      expect(record).to be_valid
    end
  end

  describe 'callbacks' do
    let(:user) { create(:user) }
    let(:notification) { create(:notification, school: user.school) }

    describe '#set_read_at' do
      it 'sets read_at before validation if nil' do
        record = described_class.new(user: user, notification_id: notification.id)
        expect(record.read_at).to be_nil
        record.valid?
        expect(record.read_at).to be_present
      end

      it 'does not override read_at if already set' do
        custom_time = 1.day.ago
        record = described_class.new(user: user, notification_id: notification.id, read_at: custom_time)
        record.valid?
        expect(record.read_at).to be_within(1.second).of(custom_time)
      end
    end
  end

  describe 'scopes' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:notification1) { create(:notification, school: user1.school) }
    let(:notification2) { create(:notification, school: user1.school) }

    before do
      described_class.create!(user: user1, notification_id: notification1.id)
      described_class.create!(user: user1, notification_id: notification2.id)
      described_class.create!(user: user2, notification_id: notification1.id)
    end

    describe '.for_user' do
      it 'returns reads for specific user' do
        expect(described_class.for_user(user1).count).to eq(2)
        expect(described_class.for_user(user2).count).to eq(1)
      end
    end

    describe '.for_notification' do
      it 'returns reads for specific notification' do
        expect(described_class.for_notification(notification1.id).count).to eq(2)
        expect(described_class.for_notification(notification2.id).count).to eq(1)
      end
    end
  end
end
