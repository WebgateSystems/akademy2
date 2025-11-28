# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Management::ApproveTeacher do
  let(:principal_role) { Role.find_or_create_by!(key: 'principal') { |r| r.name = 'Principal' } }
  let(:school_manager_role) { Role.find_or_create_by!(key: 'school_manager') { |r| r.name = 'School Manager' } }
  let(:teacher_role) { Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }

  let(:school) { create(:school) }
  let(:school_manager) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: school_manager_role, school: school)
    user
  end
  let(:teacher) do
    user = create(:user, school: school, confirmed_at: nil)
    UserRole.create!(user: user, role: teacher_role, school: school)
    user
  end

  before do
    principal_role
    school_manager_role
    teacher_role
  end

  describe '#call' do
    context 'when user is authorized' do
      let(:context) do
        {
          current_user: school_manager,
          params: { id: teacher.id }
        }
      end

      it 'approves the teacher' do
        result = described_class.call(context)

        expect(result).to be_success
        expect(result.form.confirmed_at).to be_present
        expect(result.status).to eq(:ok)
        expect(result.serializer).to eq(TeacherSerializer)
      end

      it 'resolves notification' do
        # Ensure principal and school_manager exist before creating notifications
        principal_user = create(:user, school: school)
        UserRole.create!(user: principal_user, role: principal_role, school: school)
        school_manager

        NotificationService.create_teacher_awaiting_approval(teacher: teacher, school: school)
        notification = Notification.find_by(
          notification_type: 'teacher_awaiting_approval',
          school: school,
          resolved_at: nil
        )

        expect(notification).to be_present
        expect do
          described_class.call(context)
        end.to change { notification.reload.resolved_at }.from(nil)
      end

      it 'logs approval event' do
        allow(EventLogger).to receive(:log)
        described_class.call(context)
        expect(EventLogger).to have_received(:log).with(
          event_type: 'teacher_approved',
          user: school_manager,
          school: school,
          data: {
            teacher_id: teacher.id,
            teacher_email: teacher.email
          },
          client: 'web'
        )
      end

      it 'fails when teacher is already approved' do
        teacher.update!(confirmed_at: Time.current)
        result = described_class.call(context)

        expect(result).to be_failure
        expect(result.message).to include('Nauczyciel jest już zatwierdzony')
      end

      it 'fails when teacher does not exist' do
        context[:params][:id] = SecureRandom.uuid
        result = described_class.call(context)

        expect(result).to be_failure
        expect(result.message).to include('Nauczyciel nie został znaleziony')
        expect(result.status).to eq(:not_found)
      end

      it 'fails when teacher belongs to another school' do
        other_school = create(:school)
        other_teacher = create(:user, school: other_school, confirmed_at: nil)
        UserRole.create!(user: other_teacher, role: teacher_role, school: other_school)

        context[:params][:id] = other_teacher.id
        result = described_class.call(context)

        expect(result).to be_failure
        expect(result.message).to include('Nauczyciel nie został znaleziony')
      end
    end

    context 'when user is not authorized' do
      let(:unauthorized_user) { create(:user, school: school) }
      let(:context) do
        {
          current_user: unauthorized_user,
          params: { id: teacher.id }
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
          params: { id: teacher.id }
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
