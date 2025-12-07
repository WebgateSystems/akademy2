# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NotificationService, type: :service do
  let(:school) { create(:school) }
  let!(:principal_role) { Role.find_or_create_by!(key: 'principal') { |r| r.name = 'Principal' } }
  let!(:school_manager_role) { Role.find_or_create_by!(key: 'school_manager') { |r| r.name = 'School Manager' } }
  let!(:teacher_role) { Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }
  let!(:student_role) { Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' } }

  let(:principal) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: principal_role, school: school)
    user
  end

  let(:school_manager) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: school_manager_role, school: school)
    user
  end

  describe '.create_teacher_awaiting_approval' do
    let(:teacher) do
      user = create(:user, school: school, confirmed_at: nil, first_name: 'John', last_name: 'Doe')
      UserRole.create!(user: user, role: teacher_role, school: school)
      user
    end

    before do
      # Ensure principal and school_manager exist before creating notifications
      principal
      school_manager
    end

    context 'when teacher is unconfirmed' do
      it 'creates notifications for all school managers and principals' do
        expect do
          described_class.create_teacher_awaiting_approval(teacher: teacher, school: school)
        end.to change(Notification, :count).by(2)
      end

      it 'creates notification for principal' do
        described_class.create_teacher_awaiting_approval(teacher: teacher, school: school)
        notification = Notification.find_by(
          notification_type: 'teacher_awaiting_approval',
          target_role: 'principal',
          school: school
        )
        expect(notification).to be_present
        expect(notification.metadata['teacher_id']).to eq(teacher.id.to_s)
        expect(notification.title).to eq('New teacher joined')
        expect(notification.message).to include('John Doe')
      end

      it 'creates notification for school manager' do
        described_class.create_teacher_awaiting_approval(teacher: teacher, school: school)
        notification = Notification.find_by(
          notification_type: 'teacher_awaiting_approval',
          target_role: 'school_manager',
          school: school
        )
        expect(notification).to be_present
      end

      it 'does not create duplicate notifications' do
        described_class.create_teacher_awaiting_approval(teacher: teacher, school: school)
        expect do
          described_class.create_teacher_awaiting_approval(teacher: teacher, school: school)
        end.not_to change(Notification, :count)
      end

      it 'uses email when name is not available' do
        teacher.update!(first_name: nil, last_name: nil)
        described_class.create_teacher_awaiting_approval(teacher: teacher, school: school)
        notification = Notification.find_by(
          notification_type: 'teacher_awaiting_approval',
          school: school
        )
        expect(notification.message).to include(teacher.email)
      end
    end

    context 'when teacher is already confirmed' do
      before { teacher.update!(confirmed_at: Time.current) }

      it 'does not create notifications' do
        expect do
          described_class.create_teacher_awaiting_approval(teacher: teacher, school: school)
        end.not_to change(Notification, :count)
      end
    end
  end

  describe '.resolve_teacher_notification' do
    let(:teacher) do
      user = create(:user, school: school, confirmed_at: nil)
      UserRole.create!(user: user, role: teacher_role, school: school)
      user
    end

    let!(:notification) do
      create(:notification,
             notification_type: 'teacher_awaiting_approval',
             school: school,
             target_role: 'school_manager',
             metadata: { teacher_id: teacher.id },
             resolved_at: nil)
    end

    it 'marks notification as resolved' do
      expect do
        described_class.resolve_teacher_notification(teacher: teacher, school: school)
      end.to change { notification.reload.resolved_at }.from(nil)
    end

    it 'resolves all notifications for the teacher' do
      notification2 = create(:notification,
                             notification_type: 'teacher_awaiting_approval',
                             school: school,
                             target_role: 'principal',
                             metadata: { teacher_id: teacher.id },
                             resolved_at: nil)

      described_class.resolve_teacher_notification(teacher: teacher, school: school)

      expect(notification.reload.resolved_at).to be_present
      expect(notification2.reload.resolved_at).to be_present
    end

    it 'does not resolve already resolved notifications' do
      notification.update!(resolved_at: Time.current - 1.hour)
      original_resolved_at = notification.resolved_at

      described_class.resolve_teacher_notification(teacher: teacher, school: school)

      expect(notification.reload.resolved_at).to eq(original_resolved_at)
    end
  end

  describe '.create_student_awaiting_approval' do
    let(:student) do
      user = create(:user, school: school, confirmed_at: nil, first_name: 'Jane', last_name: 'Smith')
      UserRole.create!(user: user, role: student_role, school: school)
      user
    end

    before do
      # Ensure principal and school_manager exist before creating notifications
      principal
      school_manager
    end

    context 'when student is unconfirmed' do
      it 'creates notifications for school managers' do
        expect do
          described_class.create_student_awaiting_approval(student: student, school: school)
        end.to change(Notification, :count).by(2)
      end

      it 'creates notification with correct type' do
        described_class.create_student_awaiting_approval(student: student, school: school)
        notification = Notification.find_by(
          notification_type: 'student_awaiting_approval',
          school: school
        )
        expect(notification).to be_present
        expect(notification.metadata['student_id']).to eq(student.id.to_s)
      end
    end

    context 'when student is already confirmed' do
      before { student.update!(confirmed_at: Time.current) }

      it 'does not create notifications' do
        expect do
          described_class.create_student_awaiting_approval(student: student, school: school)
        end.not_to change(Notification, :count)
      end
    end
  end

  describe '.create_notification' do
    let(:user) { create(:user, school: school) }

    it 'creates a generic notification' do
      expect do
        described_class.create_notification(
          notification_type: 'custom_type',
          title: 'Custom Title',
          message: 'Custom message',
          target_role: 'admin',
          user: user,
          school: school,
          metadata: { custom_field: 'value' }
        )
      end.to change(Notification, :count).by(1)

      notification = Notification.last
      expect(notification.notification_type).to eq('custom_type')
      expect(notification.title).to eq('Custom Title')
      expect(notification.message).to eq('Custom message')
      expect(notification.target_role).to eq('admin')
      expect(notification.metadata['custom_field']).to eq('value')
    end
  end

  describe '.create_account_deletion_request' do
    let(:student) do
      user = create(:user, school: school, first_name: 'Jan', last_name: 'Kowalski')
      UserRole.create!(user: user, role: student_role, school: school)
      user
    end

    before do
      principal
      school_manager
    end

    it 'creates notifications for school managers and principals' do
      expect do
        described_class.create_account_deletion_request(student: student, school: school)
      end.to change(Notification, :count).by(2)
    end

    it 'creates notification with correct type' do
      described_class.create_account_deletion_request(student: student, school: school)
      notification = Notification.find_by(
        notification_type: 'account_deletion_request',
        school: school
      )
      expect(notification).to be_present
      expect(notification.metadata['user_id']).to eq(student.id)
      expect(notification.metadata['user_email']).to eq(student.email)
      expect(notification.metadata['user_name']).to eq('Jan Kowalski')
    end

    it 'includes student name in message' do
      described_class.create_account_deletion_request(student: student, school: school)
      notification = Notification.find_by(
        notification_type: 'account_deletion_request',
        school: school
      )
      expect(notification.message).to include('Jan Kowalski')
    end
  end

  describe '.resolve_account_deletion_request' do
    let(:student) do
      user = create(:user, school: school)
      UserRole.create!(user: user, role: student_role, school: school)
      user
    end

    let!(:notification) do
      create(:notification,
             notification_type: 'account_deletion_request',
             school: school,
             target_role: 'school_manager',
             metadata: { 'user_id' => student.id },
             resolved_at: nil)
    end

    it 'marks notification as resolved' do
      expect do
        described_class.resolve_account_deletion_request(notification: notification)
      end.to change { notification.reload.resolved_at }.from(nil)
    end
  end

  describe '.create_account_deletion_rejected' do
    let(:student) do
      user = create(:user, school: school, first_name: 'Jan', last_name: 'Kowalski')
      UserRole.create!(user: user, role: student_role, school: school)
      user
    end

    let(:moderator) do
      user = create(:user, school: school, first_name: 'Admin', last_name: 'User')
      UserRole.create!(user: user, role: school_manager_role, school: school)
      user
    end

    let!(:original_notification) do
      create(:notification,
             notification_type: 'account_deletion_request',
             school: school,
             target_role: 'school_manager',
             metadata: { 'user_id' => student.id })
    end

    it 'creates rejection notification for student' do
      expect do
        described_class.create_account_deletion_rejected(
          student: student,
          moderator: moderator,
          notification: original_notification
        )
      end.to change(Notification, :count).by(1)
    end

    it 'creates notification with correct type and target' do
      described_class.create_account_deletion_rejected(
        student: student,
        moderator: moderator,
        notification: original_notification
      )

      notification = Notification.find_by(notification_type: 'account_deletion_rejected')
      expect(notification).to be_present
      expect(notification.target_role).to eq('student')
      expect(notification.user).to eq(student)
      expect(notification.school).to eq(school)
    end

    it 'includes moderator name in message' do
      described_class.create_account_deletion_rejected(
        student: student,
        moderator: moderator,
        notification: original_notification
      )

      notification = Notification.find_by(notification_type: 'account_deletion_rejected')
      expect(notification.message).to include('Admin User')
    end

    it 'stores moderator id in metadata' do
      described_class.create_account_deletion_rejected(
        student: student,
        moderator: moderator,
        notification: original_notification
      )

      notification = Notification.find_by(notification_type: 'account_deletion_rejected')
      expect(notification.metadata['moderator_id']).to eq(moderator.id)
      expect(notification.metadata['original_notification_id']).to eq(original_notification.id)
    end
  end
end
