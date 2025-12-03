# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Management::DestroyTeacher do
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
    context 'when declining a pending enrollment' do
      let(:teacher) do
        user = create(:user, school: nil)
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
        expect(result.status).to eq(:no_content)
      end

      it 'destroys the enrollment' do
        expect do
          described_class.call(context)
        end.to change(TeacherSchoolEnrollment, :count).by(-1)
      end

      it 'does NOT destroy the user' do
        teacher_id = teacher.id
        described_class.call(context)
        expect(User.find_by(id: teacher_id)).to be_present
      end

      it 'keeps the teacher role' do
        described_class.call(context)
        teacher.reload
        expect(teacher.roles.pluck(:key)).to include('teacher')
      end

      it 'clears school_id from user_role if it was set' do
        # Simulate old behavior where user_role had school_id
        teacher.user_roles.find_by(role: teacher_role)&.update!(school: school)

        described_class.call(context)
        teacher.reload

        teacher_user_role = teacher.user_roles.joins(:role).find_by(roles: { key: 'teacher' })
        expect(teacher_user_role&.school_id).to be_nil
      end
    end

    context 'when removing an approved teacher' do
      let(:teacher) do
        user = create(:user, school: school)
        UserRole.create!(user: user, role: teacher_role, school: school)
        user
      end
      let!(:enrollment) do
        TeacherSchoolEnrollment.create!(
          teacher: teacher,
          school: school,
          status: 'approved',
          joined_at: Time.current
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
        expect(result.status).to eq(:no_content)
      end

      it 'destroys the enrollment' do
        expect do
          described_class.call(context)
        end.to change(TeacherSchoolEnrollment, :count).by(-1)
      end

      it 'does NOT destroy the user' do
        teacher_id = teacher.id
        described_class.call(context)
        expect(User.find_by(id: teacher_id)).to be_present
      end

      it 'clears school_id from user' do
        described_class.call(context)
        teacher.reload
        expect(teacher.school_id).to be_nil
      end

      it 'clears school_id from user_role' do
        described_class.call(context)
        teacher.reload
        teacher_user_role = teacher.user_roles.joins(:role).find_by(roles: { key: 'teacher' })
        expect(teacher_user_role&.school_id).to be_nil
      end
    end

    context 'when teacher has enrollments in multiple schools' do
      let(:other_school) { create(:school) }
      let(:teacher) do
        user = create(:user, school: school)
        UserRole.create!(user: user, role: teacher_role, school: school)
        user
      end
      let!(:current_school_enrollment) do
        TeacherSchoolEnrollment.create!(
          teacher: teacher,
          school: school,
          status: 'approved',
          joined_at: Time.current
        )
      end
      let!(:other_school_enrollment) do
        TeacherSchoolEnrollment.create!(
          teacher: teacher,
          school: other_school,
          status: 'approved',
          joined_at: Time.current
        )
      end
      let(:context) do
        {
          current_user: school_manager,
          params: { id: teacher.id }
        }
      end

      it 'only removes enrollment for current school' do
        expect do
          described_class.call(context)
        end.to change(TeacherSchoolEnrollment, :count).by(-1)

        expect(TeacherSchoolEnrollment.find_by(id: current_school_enrollment.id)).to be_nil
        expect(TeacherSchoolEnrollment.find_by(id: other_school_enrollment.id)).to be_present
      end

      it 'keeps the user' do
        teacher_id = teacher.id
        described_class.call(context)
        expect(User.find_by(id: teacher_id)).to be_present
      end
    end

    context 'when teacher without enrollment (legacy)' do
      let(:teacher) do
        user = create(:user, school: school)
        UserRole.create!(user: user, role: teacher_role, school: school)
        user
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
        expect(result.status).to eq(:no_content)
      end

      it 'clears school associations' do
        described_class.call(context)
        teacher.reload
        expect(teacher.school_id).to be_nil
      end

      it 'does NOT destroy the user' do
        teacher_id = teacher.id
        described_class.call(context)
        expect(User.find_by(id: teacher_id)).to be_present
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
        user = create(:user, school: school)
        UserRole.create!(user: user, role: teacher_role, school: school)
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
