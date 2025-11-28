# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Management::CreateTeacher do
  let(:principal_role) { Role.find_or_create_by!(key: 'principal') { |r| r.name = 'Principal' } }
  let(:school_manager_role) { Role.find_or_create_by!(key: 'school_manager') { |r| r.name = 'School Manager' } }
  let(:teacher_role) { Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }

  let(:school) { create(:school) }
  let(:school_manager) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: school_manager_role, school: school)
    user
  end

  before do
    principal_role
    school_manager_role
    teacher_role
    # Create principal and school_manager before creating notifications
    principal_user = create(:user, school: school)
    UserRole.create!(user: principal_user, role: principal_role, school: school)
    # Ensure school_manager is created and persisted
    school_manager_user = school_manager
    school_manager_user.reload
    principal_user.reload
  end

  describe '#call' do
    context 'when user is authorized' do
      let(:context) do
        {
          current_user: school_manager,
          params: {
            teacher: {
              first_name: 'Jan',
              last_name: 'Kowalski',
              email: 'jan.kowalski@example.com',
              metadata: {
                phone: '+48 123 456 789'
              }
            }
          }
        }
      end

      it 'succeeds' do
        result = described_class.call(context)
        expect(result).to be_success
      end

      it 'creates teacher' do
        expect do
          described_class.call(context)
        end.to change(User, :count).by(1)
      end

      it 'assigns teacher role' do
        result = described_class.call(context)
        teacher = result.form.reload
        expect(teacher.roles.pluck(:key)).to include('teacher')
      end

      it 'assigns teacher to school' do
        result = described_class.call(context)
        teacher = result.form
        expect(teacher.school_id).to eq(school.id)
      end

      it 'generates password if not provided' do
        result = described_class.call(context)
        teacher = result.form.reload
        # Verify that password was set by checking encrypted_password (Devise field)
        expect(teacher.encrypted_password).to be_present
      end

      it 'creates notification' do
        expect do
          described_class.call(context)
        end.to change(Notification, :count).by_at_least(1)

        notification = Notification.find_by(
          notification_type: 'teacher_awaiting_approval',
          school: school
        )
        expect(notification).to be_present
      end

      it 'sets serializer' do
        result = described_class.call(context)
        expect(result.serializer).to eq(TeacherSerializer)
        expect(result.status).to eq(:created)
      end

      it 'fails when email is missing' do
        context[:params][:teacher].delete(:email)
        result = described_class.call(context)

        expect(result).to be_failure
        expect(result.message).to be_an(Array)
      end

      it 'fails when email is duplicate' do
        existing_teacher = create(:user, email: 'jan.kowalski@example.com', school: school)
        UserRole.create!(user: existing_teacher, role: teacher_role, school: school)

        result = described_class.call(context)

        expect(result).to be_failure
        expect(result.message).to be_an(Array)
      end
    end

    context 'when user is not authorized' do
      let(:unauthorized_user) { create(:user, school: school) }
      let(:context) do
        {
          current_user: unauthorized_user,
          params: {
            teacher: {
              first_name: 'Jan',
              last_name: 'Kowalski',
              email: 'jan.kowalski@example.com'
            }
          }
        }
      end

      it 'fails with authorization error' do
        result = described_class.call(context)

        expect(result).to be_failure
        expect(result.message).to include('Brak uprawnień')
      end
    end

    context 'when user has no school' do
      let(:user_without_school) do
        user = build(:user, school: nil)
        user.save(validate: false)
        # Ensure school_id is nil
        user.update_column(:school_id, nil) if user.school_id.present?
        # Create a user role for another school, then remove all roles to simulate no school access
        other_school = create(:school)
        UserRole.create!(user: user, role: school_manager_role, school: other_school)
        user.user_roles.destroy_all
        user.update_column(:school_id, nil)
        user.reload
        user
      end
      let(:context) do
        {
          current_user: user_without_school,
          params: {
            teacher: {
              first_name: 'Jan',
              last_name: 'Kowalski',
              email: 'jan.kowalski@example.com'
            }
          }
        }
      end

      it 'fails with school error' do
        result = described_class.call(context)

        expect(result).to be_failure
        expect(result.message).to include('Brak uprawnień')
      end
    end
  end
end
