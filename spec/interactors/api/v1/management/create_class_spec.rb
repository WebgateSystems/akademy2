# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Management::CreateClass do
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

  before do
    principal_role
    school_manager_role
    teacher_role
    AcademicYear.create!(school: school, year: '2025/2026', is_current: true)
  end

  describe '#call' do
    context 'when user is authorized' do
      let(:context) do
        {
          current_user: school_manager,
          params: {
            school_class: {
              name: '4A',
              year: '2025/2026',
              metadata: {}
            }
          }
        }
      end

      it 'creates a new class' do
        result = described_class.call(context)

        expect(result).to be_success
        expect(result.form).to be_a(SchoolClass)
        expect(result.form.name).to eq('4A')
        expect(result.form.year).to eq('2025/2026')
        expect(result.form.school).to eq(school)
        expect(result.status).to eq(:created)
        expect(result.serializer).to eq(SchoolClassSerializer)
      end

      it 'generates qr_token if not provided' do
        result = described_class.call(context)

        expect(result).to be_success
        expect(result.form.qr_token).to be_present
      end

      it 'assigns main teacher when teacher_id is provided' do
        context[:params][:school_class][:teacher_id] = teacher.id
        result = described_class.call(context)

        expect(result).to be_success
        result.form.reload
        assignment = TeacherClassAssignment.find_by(
          school_class: result.form,
          teacher: teacher,
          role: 'main'
        )
        expect(assignment).to be_present
      end

      it 'assigns teaching staff when teaching_staff_ids is provided' do
        context[:params][:school_class][:teaching_staff_ids] = [teacher.id, teacher2.id]
        result = described_class.call(context)

        expect(result).to be_success
        result.form.reload
        assignments = TeacherClassAssignment.where(
          school_class: result.form,
          role: 'teaching_staff'
        )
        expect(assignments.count).to eq(2)
        expect(assignments.pluck(:teacher_id)).to contain_exactly(teacher.id, teacher2.id)
      end

      it 'does not assign teacher as teaching_staff if they are main teacher' do
        context[:params][:school_class][:teacher_id] = teacher.id
        context[:params][:school_class][:teaching_staff_ids] = [teacher.id, teacher2.id]
        result = described_class.call(context)

        expect(result).to be_success
        result.form.reload
        teaching_staff_assignments = TeacherClassAssignment.where(
          school_class: result.form,
          role: 'teaching_staff'
        )
        expect(teaching_staff_assignments.pluck(:teacher_id)).not_to include(teacher.id)
        expect(teaching_staff_assignments.pluck(:teacher_id)).to include(teacher2.id)
      end

      it 'fails when name is missing' do
        context[:params][:school_class].delete(:name)
        result = described_class.call(context)

        expect(result).to be_failure
        expect(result.message).to be_an(Array)
        expect(result.message.any? { |m| m.include?('name') || m.include?('Name') }).to be true
      end

      it 'does not assign teacher from another school' do
        other_school = create(:school)
        other_teacher = create(:user, school: other_school)
        UserRole.create!(user: other_teacher, role: teacher_role, school: other_school)

        context[:params][:school_class][:teacher_id] = other_teacher.id
        result = described_class.call(context)

        expect(result).to be_success
        result.form.reload
        assignment = TeacherClassAssignment.find_by(
          school_class: result.form,
          teacher: other_teacher
        )
        expect(assignment).to be_nil
      end
    end

    context 'when user is not authorized' do
      let(:unauthorized_user) { create(:user, school: school) }
      let(:context) do
        {
          current_user: unauthorized_user,
          params: {
            school_class: {
              name: '4A',
              year: '2025/2026'
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
            school_class: {
              name: '4A',
              year: '2025/2026'
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
