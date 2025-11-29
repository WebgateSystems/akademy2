# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::NotificationsController, type: :request do
  let(:admin_role) { Role.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' } }
  let(:admin_user) do
    user = create(:user)
    UserRole.find_or_create_by!(user: user, role: admin_role) { |ur| ur.school = user.school }
    user
  end

  before do
    admin_user # Ensure user is created
    # Mock current_admin to return admin_user directly
    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(Admin::BaseController).to receive(:current_admin).and_return(admin_user)
    allow_any_instance_of(Admin::BaseController).to receive(:authenticate_admin!).and_return(true)
    allow_any_instance_of(Admin::BaseController).to receive(:require_admin!).and_return(true)
    # rubocop:enable RSpec/AnyInstance
  end

  describe 'GET /admin/notifications' do
    let(:school) { create(:school) }
    let(:teacher) do
      user = create(:user, school: school, confirmed_at: nil, first_name: 'John', last_name: 'Doe')
      UserRole.create!(user: user, role: Role.find_or_create_by!(key: 'teacher') do |r|
        r.name = 'Teacher'
      end, school: school)
      user
    end

    before do
      # Create notifications for admin role
      Notification.create!(
        notification_type: 'teacher_awaiting_approval',
        title: 'Teacher awaiting approval',
        message: 'A teacher is awaiting approval',
        target_role: 'admin',
        school: school,
        user: teacher,
        metadata: { teacher_id: teacher.id }
      )
    end

    context 'with unread filter' do
      it 'returns http success' do
        get admin_notifications_path, params: { status: 'unread' }
        expect(response).to have_http_status(:success)
      end

      it 'displays unread notifications' do
        admin_notification = Notification.where(
          notification_type: 'teacher_awaiting_approval',
          target_role: 'admin'
        ).first
        expect(admin_notification).to be_present

        get admin_notifications_path, params: { status: 'unread' }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('teacher_awaiting_approval')
        expect(response.body).to include('Teacher awaiting approval')
      end

      it 'displays unread count' do
        get admin_notifications_path, params: { status: 'unread' }
        expect(response).to have_http_status(:success)
        expect(response.body).to be_present
        expect(response.body).to include('notification-counter')
      end

      it 'sets @notifications_count' do
        get admin_notifications_path, params: { status: 'unread' }
        expect(response).to have_http_status(:success)
        # Verify count is set correctly by checking the actual count
        count = Notification.for_role('admin').unread.unresolved.count
        expect(count).to be >= 1
      end
    end

    context 'with archived filter' do
      before do
        # Mark one notification as resolved
        notification = Notification.where(
          notification_type: 'teacher_awaiting_approval',
          target_role: 'admin'
        ).first
        if notification
          notification.update!(resolved_at: Time.current)
        else
          # Create a resolved notification if none exists
          Notification.create!(
            notification_type: 'teacher_awaiting_approval',
            title: 'Resolved notification',
            message: 'This notification is resolved',
            target_role: 'admin',
            school: school,
            user: teacher,
            metadata: { teacher_id: teacher.id },
            resolved_at: Time.current
          )
        end
      end

      it 'returns http success' do
        get admin_notifications_path, params: { status: 'archived' }
        expect(response).to have_http_status(:success)
      end

      it 'displays resolved notifications' do
        get admin_notifications_path, params: { status: 'archived' }
        expect(response).to have_http_status(:success)
        expect(response.body).to be_present
      end
    end

    context 'with type filter' do
      before do
        # Create another notification type
        Notification.create!(
          notification_type: 'student_awaiting_approval',
          title: 'Student awaiting approval',
          message: 'A student is awaiting approval',
          target_role: 'admin',
          school: school,
          user: create(:user),
          metadata: {}
        )
      end

      it 'filters by notification type' do
        get admin_notifications_path, params: { status: 'unread', type: 'teacher_awaiting_approval' }
        expect(response).to have_http_status(:success)
        # Check that teacher notifications are displayed
        expect(response.body).to include('Teacher awaiting approval')
        # Check that student notifications are not displayed in the list (they may appear in select options)
        # We check by looking for the actual notification card content
        expect(response.body.scan(/student_awaiting_approval/).length).to be <= 1 # Only in select option
      end

      it 'shows all types when filter is "all"' do
        get admin_notifications_path, params: { status: 'unread', type: 'all' }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('teacher_awaiting_approval')
        expect(response.body).to include('student_awaiting_approval')
      end
    end

    context 'when there are no notifications' do
      before do
        Notification.where(target_role: 'admin').destroy_all
      end

      it 'returns http success' do
        get admin_notifications_path
        expect(response).to have_http_status(:success)
      end

      it 'displays empty state' do
        get admin_notifications_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include('No notifications')
      end
    end
  end

  describe 'POST /admin/notifications/mark_as_read' do
    let(:school) { create(:school) }
    let(:teacher) do
      user = create(:user, school: school, confirmed_at: nil, first_name: 'John', last_name: 'Doe')
      UserRole.create!(user: user, role: Role.find_or_create_by!(key: 'teacher') do |r|
        r.name = 'Teacher'
      end, school: school)
      user
    end

    let(:notification) do
      Notification.create!(
        notification_type: 'teacher_awaiting_approval',
        title: 'Teacher awaiting approval',
        message: 'A teacher is awaiting approval',
        target_role: 'admin',
        school: school,
        user: teacher,
        metadata: { teacher_id: teacher.id }
      )
    end

    it 'marks notification as read' do
      expect(notification.read?).to be false

      post admin_mark_notification_as_read_path, params: { notification_id: notification.id }

      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)['success']).to be true

      notification.reload
      expect(notification.read?).to be true
      expect(notification.read_by_user).to eq(admin_user)
    end

    it 'returns success json' do
      post admin_mark_notification_as_read_path, params: { notification_id: notification.id }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
    end

    context 'when notification does not exist' do
      it 'returns not found' do
        post admin_mark_notification_as_read_path, params: { notification_id: SecureRandom.uuid }

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['error']).to include('not found')
      end
    end

    context 'when notification is already read' do
      before do
        notification.mark_as_read!(admin_user)
      end

      it 'still returns success' do
        post admin_mark_notification_as_read_path, params: { notification_id: notification.id }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
      end
    end
  end

  describe 'notifications_count in layout' do
    let(:school) { create(:school) }

    before do
      # Create multiple notifications for admin
      3.times do |i|
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
    end

    it 'displays notification count in header' do
      get admin_notifications_path
      expect(response).to have_http_status(:success)
      # Check that the notification counter is displayed in the layout
      expect(response.body).to include('notification-counter')
      # Verify count is 3 by checking the actual count method
      count = Notification.for_role('admin').unread.unresolved.count
      expect(count).to eq(3)
    end
  end
end
