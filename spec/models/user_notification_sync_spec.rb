# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'notification synchronization callbacks' do
    let(:school) { create(:school) }
    let!(:teacher_role) { Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }
    let!(:student_role) { Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' } }
    let!(:principal_role) { Role.find_or_create_by!(key: 'principal') { |r| r.name = 'Principal' } }
    let!(:school_manager_role) { Role.find_or_create_by!(key: 'school_manager') { |r| r.name = 'School Manager' } }

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

    describe 'for teachers' do
      let(:teacher) do
        user = create(:user, school: school, confirmed_at: Time.current, first_name: 'John', last_name: 'Doe')
        UserRole.create!(user: user, role: teacher_role, school: school)
        user
      end

      before do
        # Ensure principal and school_manager exist before creating notifications
        principal
        school_manager
      end

      context 'when confirmed_at changes from present to nil' do
        it 'creates notification for awaiting approval' do
          expect do
            teacher.update!(confirmed_at: nil)
          end.to change(Notification, :count).by(2) # One for principal, one for school_manager
        end

        it 'creates notification with correct type' do
          teacher.update!(confirmed_at: nil)
          notification = Notification.find_by(
            notification_type: 'teacher_awaiting_approval',
            school: school
          )
          expect(notification).to be_present
          expect(notification.metadata['teacher_id']).to eq(teacher.id.to_s)
        end
      end

      context 'when confirmed_at changes from nil to present' do
        before do
          teacher.update!(confirmed_at: nil)
          NotificationService.create_teacher_awaiting_approval(teacher: teacher, school: school)
        end

        it 'resolves existing notifications' do
          notifications = Notification.where(
            notification_type: 'teacher_awaiting_approval',
            school: school
          ).where("metadata->>'teacher_id' = ?", teacher.id.to_s)
          expect(notifications.all? { |n| n.resolved_at.nil? }).to be true

          teacher.update!(confirmed_at: Time.current)

          notifications.reload
          expect(notifications.all? { |n| n.resolved_at.present? }).to be true
        end
      end

      context 'when confirmed_at does not change' do
        it 'does not create or resolve notifications' do
          teacher.update!(first_name: 'Jane')
          expect(Notification.count).to eq(0)
        end
      end
    end

    describe 'for students' do
      let(:student) do
        user = create(:user, school: school, confirmed_at: Time.current)
        UserRole.create!(user: user, role: student_role, school: school)
        user
      end

      before do
        # Ensure principal and school_manager exist before creating notifications
        principal
        school_manager
      end

      context 'when confirmed_at changes from present to nil' do
        it 'creates notification for awaiting approval' do
          expect do
            student.update!(confirmed_at: nil)
          end.to change(Notification, :count).by(2)
        end

        it 'creates notification with student_awaiting_approval type' do
          student.update!(confirmed_at: nil)
          notification = Notification.find_by(
            notification_type: 'student_awaiting_approval',
            school: school
          )
          expect(notification).to be_present
        end
      end
    end

    describe 'for non-teacher/non-student users' do
      let(:admin_role) { Role.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' } }
      let(:admin_user) do
        user = create(:user, school: school)
        UserRole.create!(user: user, role: admin_role, school: school)
        user
      end

      it 'does not create notifications' do
        expect do
          admin_user.update!(confirmed_at: nil)
        end.not_to change(Notification, :count)
      end
    end

    describe 'when user has no school' do
      let(:teacher) do
        user = create(:user, school: nil, confirmed_at: Time.current)
        UserRole.create!(user: user, role: teacher_role, school: create(:school))
        user
      end

      it 'does not create notifications' do
        expect do
          teacher.update!(confirmed_at: nil)
        end.not_to change(Notification, :count)
      end
    end
  end
end
