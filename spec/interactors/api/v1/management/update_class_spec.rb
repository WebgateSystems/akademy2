# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Management::UpdateClass do
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
    user = create(:user, school: school)
    UserRole.create!(user: user, role: teacher_role, school: school)
    user
  end
  let(:teacher2) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: teacher_role, school: school)
    user
  end
  let(:school_class) do
    SchoolClass.create!(
      school: school,
      name: '4A',
      year: '2025/2026',
      qr_token: SecureRandom.uuid,
      metadata: {}
    )
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
          params: {
            id: school_class.id,
            school_class: {
              name: '4B'
            }
          }
        }
      end

      it 'updates the class' do
        result = described_class.call(context)

        expect(result).to be_success
        expect(result.form.name).to eq('4B')
        expect(result.status).to eq(:ok)
        expect(result.serializer).to eq(SchoolClassSerializer)
      end

      it 'updates main teacher assignment' do
        context[:params][:school_class][:teacher_id] = teacher.id
        result = described_class.call(context)

        expect(result).to be_success
        assignment = TeacherClassAssignment.find_by(
          school_class: school_class,
          teacher: teacher,
          role: 'main'
        )
        expect(assignment).to be_present
      end

      it 'removes main teacher when teacher_id is empty string' do
        TeacherClassAssignment.create!(
          school_class: school_class,
          teacher: teacher,
          role: 'main'
        )
        context[:params][:school_class][:teacher_id] = ''
        result = described_class.call(context)

        expect(result).to be_success
        assignment = TeacherClassAssignment.find_by(
          school_class: school_class,
          role: 'main'
        )
        expect(assignment).to be_nil
      end

      it 'updates teaching staff assignments' do
        context[:params][:school_class][:teaching_staff_ids] = [teacher.id, teacher2.id]
        result = described_class.call(context)

        expect(result).to be_success
        assignments = TeacherClassAssignment.where(
          school_class: school_class,
          role: 'teaching_staff'
        )
        expect(assignments.count).to eq(2)
        expect(assignments.pluck(:teacher_id)).to contain_exactly(teacher.id, teacher2.id)
      end

      it 'removes all teaching staff when teaching_staff_ids is empty array' do
        TeacherClassAssignment.create!(
          school_class: school_class,
          teacher: teacher,
          role: 'teaching_staff'
        )
        context[:params][:school_class][:teaching_staff_ids] = []
        result = described_class.call(context)

        expect(result).to be_success
        assignments = TeacherClassAssignment.where(
          school_class: school_class,
          role: 'teaching_staff'
        )
        expect(assignments.count).to eq(0)
      end

      it 'does not assign teacher as teaching_staff if they are main teacher' do
        context[:params][:school_class][:teacher_id] = teacher.id
        context[:params][:school_class][:teaching_staff_ids] = [teacher.id, teacher2.id]
        result = described_class.call(context)

        expect(result).to be_success
        teaching_staff_assignments = TeacherClassAssignment.where(
          school_class: school_class,
          role: 'teaching_staff'
        )
        expect(teaching_staff_assignments.pluck(:teacher_id)).not_to include(teacher.id)
        expect(teaching_staff_assignments.pluck(:teacher_id)).to include(teacher2.id)
      end

      it 'fails when class does not exist' do
        context[:params][:id] = SecureRandom.uuid
        result = described_class.call(context)

        expect(result).to be_failure
        expect(result.message).to include('Klasa nie została znaleziona')
        expect(result.status).to eq(:not_found)
      end

      it 'fails when class belongs to another school' do
        other_school = create(:school)
        other_class = SchoolClass.create!(
          school: other_school,
          name: '5A',
          year: '2025/2026',
          qr_token: SecureRandom.uuid,
          metadata: {}
        )
        context[:params][:id] = other_class.id
        result = described_class.call(context)

        expect(result).to be_failure
        expect(result.message).to include('Klasa nie została znaleziona')
      end
    end

    context 'when user is not authorized' do
      let(:unauthorized_user) { create(:user, school: school) }
      let(:context) do
        {
          current_user: unauthorized_user,
          params: {
            id: school_class.id,
            school_class: {
              name: '4B'
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
            id: school_class.id,
            school_class: {
              name: '4B'
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
