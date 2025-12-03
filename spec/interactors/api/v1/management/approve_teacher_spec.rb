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

  before do
    principal_role
    school_manager_role
    teacher_role
  end

  describe '#call' do
    context 'when approving a pending enrollment' do
      let(:teacher) do
        user = create(:user, school: nil, confirmed_at: Time.current)
        UserRole.create!(user: user, role: teacher_role, school: nil)
        user
      end
      let!(:enrollment) do
        TeacherSchoolEnrollment.create!(
          teacher: teacher,
          school: school,
          status: 'pending'
        )
      end
      let(:context) do
        {
          current_user: school_manager,
          params: { id: teacher.id }
        }
      end

      it 'succeeds' do
        result = described_class.call(context)
        expect(result).to be_success
        expect(result.status).to eq(:ok)
      end

      it 'updates enrollment status to approved' do
        described_class.call(context)
        enrollment.reload
        expect(enrollment.status).to eq('approved')
        expect(enrollment.joined_at).to be_present
      end

      it 'assigns school_id to user' do
        described_class.call(context)
        teacher.reload
        expect(teacher.school_id).to eq(school.id)
      end

      it 'assigns school_id to user_role' do
        described_class.call(context)
        teacher.reload
        teacher_user_role = teacher.user_roles.joins(:role).find_by(roles: { key: 'teacher' })
        expect(teacher_user_role.school_id).to eq(school.id)
      end

      it 'resolves enrollment notification' do
        # Ensure school_manager exists before creating notification
        school_manager
        NotificationService.create_teacher_enrollment_request(teacher: teacher, school: school)
        notification = Notification.find_by(
          notification_type: 'teacher_enrollment_request',
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
          data: hash_including(
            teacher_id: teacher.id,
            teacher_email: teacher.email
          ),
          client: 'web'
        )
      end
    end

    context 'when teacher is already approved for this school' do
      let(:teacher) do
        user = create(:user, school: school, confirmed_at: Time.current)
        UserRole.create!(user: user, role: teacher_role, school: school)
        user
      end
      let!(:enrollment) do
        TeacherSchoolEnrollment.create!(
          teacher: teacher,
          school: school,
          status: 'approved',
          joined_at: 1.day.ago
        )
      end
      let(:context) do
        {
          current_user: school_manager,
          params: { id: teacher.id }
        }
      end

      it 'fails with already approved message' do
        result = described_class.call(context)
        expect(result).to be_failure
        expect(result.message.join).to include('zatwierdzony')
      end
    end

    context 'when teacher without enrollment (legacy)' do
      let(:teacher) do
        user = create(:user, school: school, confirmed_at: nil)
        UserRole.create!(user: user, role: teacher_role, school: school)
        user
      end
      let(:context) do
        {
          current_user: school_manager,
          params: { id: teacher.id }
        }
      end

      it 'approves by confirming the user' do
        result = described_class.call(context)
        expect(result).to be_success
        teacher.reload
        expect(teacher.confirmed_at).to be_present
      end
    end

    context 'when teacher does not exist' do
      let(:context) do
        {
          current_user: school_manager,
          params: { id: SecureRandom.uuid }
        }
      end

      it 'fails with not found' do
        result = described_class.call(context)
        expect(result).to be_failure
        expect(result.message).to include('Nauczyciel nie został znaleziony')
        expect(result.status).to eq(:not_found)
      end
    end

    context 'when teacher belongs to another school' do
      let(:other_school) { create(:school) }
      let(:other_teacher) do
        user = create(:user, school: other_school)
        UserRole.create!(user: user, role: teacher_role, school: other_school)
        user
      end
      let(:context) do
        {
          current_user: school_manager,
          params: { id: other_teacher.id }
        }
      end

      it 'fails with not found' do
        result = described_class.call(context)
        expect(result).to be_failure
        expect(result.message).to include('Nauczyciel nie został znaleziony')
      end
    end

    context 'when user is not authorized' do
      let(:unauthorized_user) { create(:user, school: school) }
      let(:teacher) do
        user = create(:user, school: nil)
        UserRole.create!(user: user, role: teacher_role, school: nil)
        TeacherSchoolEnrollment.create!(teacher: user, school: school, status: 'pending')
        user
      end
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
  end
end
