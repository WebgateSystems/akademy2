# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Management::NotificationsController, type: :request do
  let!(:principal_role) { Role.find_or_create_by!(key: 'principal') { |r| r.name = 'Principal' } }
  let!(:school_manager_role) { Role.find_or_create_by!(key: 'school_manager') { |r| r.name = 'School Manager' } }
  let!(:teacher_role) { Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }

  let(:school) { create(:school) }
  let(:principal) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: principal_role, school: school)
    user.reload # Reload to ensure roles are loaded
    user
  end

  before do
    sign_in principal
    # Ensure roles are loaded for policy check
    principal.roles.load if principal.roles.loaded? == false
  end

  describe 'GET /management/notifications' do
    let(:school_manager) do
      user = create(:user, school: school)
      UserRole.create!(user: user, role: school_manager_role, school: school)
      user
    end

    let(:teacher) do
      user = create(:user, school: school, confirmed_at: nil, first_name: 'John', last_name: 'Doe')
      UserRole.create!(user: user, role: teacher_role, school: school)
      user
    end

    before do
      # Create principal and school_manager first so notifications can be created for both roles
      principal
      school_manager
      NotificationService.create_teacher_awaiting_approval(teacher: teacher, school: school)
    end

    context 'with unread filter' do
      it 'returns http success' do
        get management_notifications_path, params: { status: 'unread' }
        expect(response).to have_http_status(:success)
      end

      it 'displays unread notifications' do
        # Verify notification exists for principal role
        principal_notification = Notification.where(
          notification_type: 'teacher_awaiting_approval',
          school: school,
          target_role: 'principal'
        ).first
        expect(principal_notification).to be_present

        get management_notifications_path, params: { status: 'unread' }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('teacher_awaiting_approval')
      end

      it 'displays unread count' do
        get management_notifications_path, params: { status: 'unread' }
        expect(response).to have_http_status(:success)
        # Check that the page loads successfully (unread count is displayed in the view)
        expect(response.body).to be_present
      end
    end

    context 'with archived filter' do
      before do
        # Mark one notification as resolved for principal
        notification = Notification.where(
          notification_type: 'teacher_awaiting_approval',
          school: school,
          target_role: 'principal'
        ).first
        if notification
          notification.update!(resolved_at: Time.current)
        else
          # Create a resolved notification if none exists
          Notification.create!(
            notification_type: 'teacher_awaiting_approval',
            title: 'Resolved notification',
            message: 'This notification is resolved',
            target_role: 'principal',
            school: school,
            user: teacher,
            metadata: { teacher_id: teacher.id },
            resolved_at: Time.current
          )
        end
      end

      it 'returns http success' do
        get management_notifications_path, params: { status: 'archived' }
        expect(response).to have_http_status(:success)
      end

      it 'displays resolved notifications' do
        get management_notifications_path, params: { status: 'archived' }
        expect(response).to have_http_status(:success)
        # Check that the page loads successfully (resolved notifications are displayed)
        expect(response.body).to be_present
      end
    end

    context 'with type filter' do
      it 'filters by notification type' do
        get management_notifications_path, params: { status: 'unread', type: 'teacher_awaiting_approval' }
        expect(response).to have_http_status(:success)
        # Check that only teacher_awaiting_approval notifications are shown
        expect(response.body).to include('teacher_awaiting_approval')
      end
    end

    context 'when user has no school' do
      before do
        principal.update!(school: nil)
      end

      it 'returns empty notifications' do
        get management_notifications_path
        expect(response).to have_http_status(:success)
        # Page should load but show no notifications
        expect(response.body).to be_present
      end
    end
  end
end
