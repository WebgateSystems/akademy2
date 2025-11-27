# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Notification, type: :model do
  let(:school) { create(:school) }
  let(:user) { create(:user, school: school) }
  let(:manager) { create(:user, school: school) }

  describe 'associations' do
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to belong_to(:school).optional }
    it { is_expected.to belong_to(:read_by_user).optional }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:notification_type) }
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:message) }
    it { is_expected.to validate_presence_of(:target_role) }
  end

  describe 'scopes' do
    let!(:unread_notification) do
      create(:notification, read_at: nil, school: school, target_role: 'school_manager')
    end
    let!(:read_notification) do
      create(:notification, read_at: Time.current, school: school, target_role: 'school_manager')
    end
    let!(:resolved_notification) do
      create(:notification, resolved_at: Time.current, school: school, target_role: 'school_manager')
    end
    let!(:unresolved_notification) do
      create(:notification, resolved_at: nil, school: school, target_role: 'school_manager')
    end

    describe '.unread' do
      it 'returns only unread notifications' do
        expect(described_class.unread).to include(unread_notification)
        expect(described_class.unread).not_to include(read_notification)
      end
    end

    describe '.read' do
      it 'returns only read notifications' do
        expect(described_class.read).to include(read_notification)
        expect(described_class.read).not_to include(unread_notification)
      end
    end

    describe '.resolved' do
      it 'returns only resolved notifications' do
        expect(described_class.resolved).to include(resolved_notification)
        expect(described_class.resolved).not_to include(unresolved_notification)
      end
    end

    describe '.unresolved' do
      it 'returns only unresolved notifications' do
        expect(described_class.unresolved).to include(unresolved_notification)
        expect(described_class.unresolved).not_to include(resolved_notification)
      end
    end

    describe '.for_role' do
      let!(:admin_notification) do
        create(:notification, target_role: 'admin', school: school)
      end

      it 'returns notifications for specific role' do
        expect(described_class.for_role('school_manager')).to include(unread_notification)
        expect(described_class.for_role('school_manager')).not_to include(admin_notification)
      end
    end

    describe '.for_school' do
      let(:other_school) { create(:school) }
      let!(:other_school_notification) do
        create(:notification, school: other_school, target_role: 'school_manager')
      end

      it 'returns notifications for specific school' do
        expect(described_class.for_school(school)).to include(unread_notification)
        expect(described_class.for_school(school)).not_to include(other_school_notification)
      end
    end

    describe '.recent' do
      it 'orders by created_at descending' do
        notifications = described_class.recent.limit(2)
        expect(notifications.first.created_at).to be >= notifications.second.created_at
      end
    end
  end

  describe '#read?' do
    it 'returns true when read_at is present' do
      notification = create(:notification, read_at: Time.current)
      expect(notification.read?).to be true
    end

    it 'returns false when read_at is nil' do
      notification = create(:notification, read_at: nil)
      expect(notification.read?).to be false
    end
  end

  describe '#resolved?' do
    it 'returns true when resolved_at is present' do
      notification = create(:notification, resolved_at: Time.current)
      expect(notification.resolved?).to be true
    end

    it 'returns false when resolved_at is nil' do
      notification = create(:notification, resolved_at: nil)
      expect(notification.resolved?).to be false
    end
  end

  describe '#mark_as_read!' do
    let(:notification) { create(:notification, read_at: nil) }

    it 'marks notification as read' do
      expect { notification.mark_as_read!(manager) }.to change(notification, :read?).from(false).to(true)
    end

    it 'sets read_by_user' do
      notification.mark_as_read!(manager)
      expect(notification.read_by_user).to eq(manager)
    end

    it 'does not mark as read if already read' do
      notification.update!(read_at: Time.current - 1.hour)
      original_read_at = notification.read_at
      notification.mark_as_read!(manager)
      expect(notification.read_at).to eq(original_read_at)
    end
  end

  describe '#mark_as_resolved!' do
    let(:notification) { create(:notification, resolved_at: nil) }

    it 'marks notification as resolved' do
      expect { notification.mark_as_resolved! }.to change(notification, :resolved?).from(false).to(true)
    end

    it 'does not mark as resolved if already resolved' do
      notification.update!(resolved_at: Time.current - 1.hour)
      original_resolved_at = notification.resolved_at
      notification.mark_as_resolved!
      expect(notification.resolved_at).to eq(original_resolved_at)
    end
  end
end
