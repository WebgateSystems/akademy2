# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Management::CreateStudent do
  let(:principal_role) { Role.find_or_create_by!(key: 'principal') { |r| r.name = 'Principal' } }
  let(:school_manager_role) { Role.find_or_create_by!(key: 'school_manager') { |r| r.name = 'School Manager' } }
  let(:student_role) { Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' } }

  let(:school) { create(:school) }
  let(:school_class) do
    SchoolClass.create!(
      school: school,
      name: '4A',
      year: '2025/2026',
      qr_token: SecureRandom.uuid,
      metadata: {}
    )
  end
  let(:school_manager) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: school_manager_role, school: school)
    user
  end

  describe '#call' do
    context 'when user is authorized' do
      let(:context) do
        {
          current_user: school_manager,
          params: {
            student: {
              first_name: 'Jan',
              last_name: 'Kowalski',
              email: 'jan.kowalski@example.com',
              school_class_id: school_class.id,
              metadata: {
                phone: '+48 123 456 789',
                birth_date: '15.03.2010'
              }
            }
          }
        }
      end

      before do
        principal_role
        school_manager_role
        student_role
        # Create principal and school_manager before creating notifications
        principal_user = create(:user, school: school)
        UserRole.create!(user: principal_user, role: principal_role, school: school)
        school_manager
        school_class
      end

      it 'succeeds' do
        result = described_class.call(context)
        expect(result).to be_success
      end

      it 'creates student' do
        expect do
          described_class.call(context)
        end.to change(User, :count).by(1)
      end

      it 'assigns student role' do
        result = described_class.call(context)
        student = result.form
        expect(student.roles.pluck(:key)).to include('student')
      end

      it 'assigns student to school' do
        result = described_class.call(context)
        student = result.form
        expect(student.school_id).to eq(school.id)
      end

      it 'assigns student to class' do
        result = described_class.call(context)
        student = result.form
        enrollment = StudentClassEnrollment.find_by(student: student, school_class: school_class)
        expect(enrollment).to be_present
      end

      it 'creates notification' do
        expect do
          described_class.call(context)
        end.to change(Notification, :count).by_at_least(1)

        notification = Notification.find_by(
          notification_type: 'student_awaiting_approval',
          school: school
        )
        expect(notification).to be_present
      end

      it 'sets serializer' do
        result = described_class.call(context)
        expect(result.serializer).to eq(StudentSerializer)
      end
    end

    context 'when user is not authorized' do
      let(:admin_role) { Role.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' } }
      let(:admin_user) do
        user = create(:user, school: school)
        UserRole.create!(user: user, role: admin_role, school: school)
        user
      end
      let(:context) do
        {
          current_user: admin_user,
          params: {
            student: {
              first_name: 'Jan',
              last_name: 'Kowalski',
              email: 'jan.kowalski@example.com'
            }
          }
        }
      end

      it 'fails' do
        result = described_class.call(context)
        expect(result).to be_failure
      end
    end

    context 'with invalid params' do
      let(:context) do
        {
          current_user: school_manager,
          params: {
            student: {
              email: 'invalid-email'
            }
          }
        }
      end

      before do
        principal_role
        school_manager_role
        student_role
        school_manager
        school_class
      end

      it 'fails' do
        result = described_class.call(context)
        expect(result).to be_failure
      end

      it 'sets error messages' do
        result = described_class.call(context)
        expect(result.message).to be_present
      end
    end
  end
end
