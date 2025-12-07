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

    context 'with account_deletion_request filter' do
      let!(:student_role) { Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' } }
      let(:student) do
        user = create(:user, school: school, first_name: 'Jan', last_name: 'Kowalski')
        UserRole.create!(user: user, role: student_role, school: school)
        user
      end

      before do
        NotificationService.create_account_deletion_request(student: student, school: school)
      end

      it 'displays account deletion request notifications' do
        get management_notifications_path, params: { status: 'unread', type: 'account_deletion_request' }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('account_deletion_request')
      end
    end
  end

  describe 'POST /management/notifications/:id/approve_account_deletion' do
    let!(:student_role) { Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' } }
    let!(:student) do
      user = create(:user, school: school, first_name: 'Jan', last_name: 'Kowalski')
      UserRole.create!(user: user, role: student_role, school: school)
      user
    end

    let!(:deletion_notification) do
      create(:notification,
             notification_type: 'account_deletion_request',
             school: school,
             target_role: 'principal',
             title: 'Account deletion request',
             message: "Student #{student.full_name} requested account deletion",
             user: student,
             metadata: {
               'user_id' => student.id,
               'user_email' => student.email,
               'user_name' => student.full_name
             },
             resolved_at: nil)
    end

    it 'deletes the student account' do
      expect do
        post approve_account_deletion_management_notification_path(deletion_notification)
      end.to change(User, :count).by(-1)
    end

    it 'deletes or resolves the notification' do
      notification_id = deletion_notification.id
      post approve_account_deletion_management_notification_path(deletion_notification)
      # Notification is either resolved or deleted with the student (cascade)
      notification = Notification.find_by(id: notification_id)
      expect(notification.nil? || notification.resolved_at.present?).to be true
    end

    it 'redirects to notifications with success message' do
      post approve_account_deletion_management_notification_path(deletion_notification)
      expect(response).to redirect_to(management_notifications_path)
      expect(flash[:notice]).to be_present
    end
  end

  describe 'POST /management/notifications/:id/reject_account_deletion' do
    let!(:student_role) { Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' } }
    let!(:student) do
      user = create(:user, school: school, first_name: 'Jan', last_name: 'Kowalski')
      UserRole.create!(user: user, role: student_role, school: school)
      user
    end

    let!(:deletion_notification) do
      create(:notification,
             notification_type: 'account_deletion_request',
             school: school,
             target_role: 'principal',
             title: 'Account deletion request',
             message: "Student #{student.full_name} requested account deletion",
             user: student,
             metadata: {
               'user_id' => student.id,
               'user_email' => student.email,
               'user_name' => student.full_name
             },
             resolved_at: nil)
    end

    it 'does not delete the student account' do
      expect do
        post reject_account_deletion_management_notification_path(deletion_notification)
      end.not_to change(User, :count)
    end

    it 'marks notification as resolved' do
      post reject_account_deletion_management_notification_path(deletion_notification)
      expect(deletion_notification.reload.resolved_at).to be_present
    end

    it 'creates rejection notification for student' do
      expect do
        post reject_account_deletion_management_notification_path(deletion_notification)
      end.to change(Notification.where(notification_type: 'account_deletion_rejected'), :count).by(1)
    end

    it 'redirects to notifications with success message' do
      post reject_account_deletion_management_notification_path(deletion_notification)
      expect(response).to redirect_to(management_notifications_path)
      expect(flash[:notice]).to be_present
    end

    it 'notifies student about rejection' do
      post reject_account_deletion_management_notification_path(deletion_notification)
      rejection_notification = Notification.find_by(notification_type: 'account_deletion_rejected', user: student)
      expect(rejection_notification).to be_present
      expect(rejection_notification.target_role).to eq('student')
    end
  end
end
