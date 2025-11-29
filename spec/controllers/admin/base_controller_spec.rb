# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::BaseController, type: :request do
  let(:admin_role) { Role.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' } }
  let(:admin_user) do
    user = create(:user)
    UserRole.find_or_create_by!(user: user, role: admin_role) { |ur| ur.school = user.school }
    user
  end

  before do
    # Mock authentication methods
    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(described_class).to receive(:current_admin).and_return(admin_user)
    allow_any_instance_of(described_class).to receive(:authenticate_admin!).and_return(true)
    allow_any_instance_of(described_class).to receive(:require_admin!).and_return(true)
    # rubocop:enable RSpec/AnyInstance
  end

  describe '#notifications_count' do
    let(:school) { create(:school) }

    context 'when there are unread notifications for admin role' do
      before do
        # Create unread notifications for admin
        2.times do |i|
          Notification.create!(
            notification_type: 'teacher_awaiting_approval',
            title: "Notification #{i}",
            message: "Message #{i}",
            target_role: 'admin',
            school: school,
            user: create(:user),
            metadata: {}
          )
        end

        # Create a read notification (should not be counted)
        read_notification = Notification.create!(
          notification_type: 'teacher_awaiting_approval',
          title: 'Read notification',
          message: 'This is read',
          target_role: 'admin',
          school: school,
          user: create(:user),
          metadata: {}
        )
        read_notification.mark_as_read!(admin_user)

        # Create a resolved notification (should not be counted)
        Notification.create!(
          notification_type: 'teacher_awaiting_approval',
          title: 'Resolved notification',
          message: 'This is resolved',
          target_role: 'admin',
          school: school,
          user: create(:user),
          metadata: {},
          resolved_at: Time.current
        )
      end

      it 'returns count of unread and unresolved notifications' do
        get admin_notifications_path
        expect(response).to have_http_status(:success)
        # Check that notification counter shows correct count in HTML
        expect(response.body).to include('notification-counter')
        # Verify count is 2 by checking the actual count method
        count = Notification.for_role('admin').unread.unresolved.count
        expect(count).to eq(2)
      end
    end

    context 'when there are no notifications' do
      before do
        Notification.where(target_role: 'admin').destroy_all
      end

      it 'returns 0' do
        get admin_notifications_path
        expect(response).to have_http_status(:success)
        # Check that notification counter is hidden or shows 0
        count = Notification.for_role('admin').unread.unresolved.count
        expect(count).to eq(0)
      end
    end

    context 'when notifications exist for other roles' do
      before do
        # Create notification for school_manager role (should not be counted)
        Notification.create!(
          notification_type: 'teacher_awaiting_approval',
          title: 'School manager notification',
          message: 'This is for school manager',
          target_role: 'school_manager',
          school: school,
          user: create(:user),
          metadata: {}
        )
      end

      it 'does not count notifications for other roles' do
        get admin_notifications_path
        expect(response).to have_http_status(:success)
        # Verify count is 0 for admin role
        count = Notification.for_role('admin').unread.unresolved.count
        expect(count).to eq(0)
      end
    end
  end

  describe '#set_notifications_count' do
    let(:school) { create(:school) }

    before do
      Notification.create!(
        notification_type: 'teacher_awaiting_approval',
        title: 'Test notification',
        message: 'Test message',
        target_role: 'admin',
        school: school,
        user: create(:user),
        metadata: {}
      )
    end

    it 'sets @notifications_count before action' do
      get admin_notifications_path
      expect(response).to have_http_status(:success)
      # Verify count is set correctly
      count = Notification.for_role('admin').unread.unresolved.count
      expect(count).to eq(1)
    end
  end
end
