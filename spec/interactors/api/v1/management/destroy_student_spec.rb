# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Management::DestroyStudent do
  let(:principal_role) { Role.find_or_create_by!(key: 'principal') { |r| r.name = 'Principal' } }
  let(:school_manager_role) { Role.find_or_create_by!(key: 'school_manager') { |r| r.name = 'School Manager' } }
  let(:student_role) { Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' } }
  let(:teacher_role) { Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }

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

  before do
    principal_role
    school_manager_role
    student_role
  end

  describe '#call' do
    context 'when declining/removing a student with approved enrollment' do
      let(:student) do
        user = create(:user, school: school)
        UserRole.create!(user: user, role: student_role, school: school)
        StudentClassEnrollment.create!(student: user, school_class: school_class, status: 'approved')
        user.reload
      end
      let(:context) { { current_user: school_manager, params: { id: student.id } } }

      before do
        school_manager
        school_class
        student
      end

      it 'succeeds' do
        result = described_class.call(context)
        expect(result).to be_success
        expect(result.status).to eq(:no_content)
      end

      it 'destroys the enrollment' do
        expect do
          described_class.call(context)
        end.to change(StudentClassEnrollment, :count).by(-1)
      end

      it 'does NOT destroy the user' do
        student_id = student.id
        described_class.call(context)
        expect(User.find_by(id: student_id)).to be_present
      end

      it 'clears school_id from user' do
        described_class.call(context)
        student.reload
        expect(student.school_id).to be_nil
      end
    end

    context 'when declining a student with pending enrollment' do
      let(:student) do
        user = create(:user, school: school)
        UserRole.create!(user: user, role: student_role, school: school)
        StudentClassEnrollment.create!(student: user, school_class: school_class, status: 'pending')
        user.reload
      end
      let(:context) { { current_user: school_manager, params: { id: student.id } } }

      before do
        school_manager
        school_class
        student
      end

      it 'succeeds' do
        result = described_class.call(context)
        expect(result).to be_success
      end

      it 'destroys the enrollment' do
        expect do
          described_class.call(context)
        end.to change(StudentClassEnrollment, :count).by(-1)
      end

      it 'does NOT destroy the user' do
        student_id = student.id
        described_class.call(context)
        expect(User.find_by(id: student_id)).to be_present
      end
    end

    context 'when student has enrollments in multiple classes' do
      let(:other_class) do
        SchoolClass.create!(
          school: school,
          name: '5B',
          year: '2025/2026',
          qr_token: SecureRandom.uuid,
          metadata: {}
        )
      end
      let(:student) do
        user = create(:user, school: school)
        UserRole.create!(user: user, role: student_role, school: school)
        StudentClassEnrollment.create!(student: user, school_class: school_class, status: 'approved')
        StudentClassEnrollment.create!(student: user, school_class: other_class, status: 'approved')
        user.reload
      end
      let(:context) { { current_user: school_manager, params: { id: student.id } } }

      before do
        school_manager
        school_class
        other_class
        student
      end

      it 'removes all enrollments in this school' do
        expect do
          described_class.call(context)
        end.to change(StudentClassEnrollment, :count).by(-2)
      end

      it 'keeps the user' do
        student_id = student.id
        described_class.call(context)
        expect(User.find_by(id: student_id)).to be_present
      end
    end

    context 'when teacher declines student in their class' do
      let(:teacher) do
        user = create(:user, school: school)
        UserRole.create!(user: user, role: teacher_role, school: school)
        TeacherClassAssignment.create!(teacher: user, school_class: school_class, role: 'teacher')
        user.reload
      end
      let(:student) do
        user = create(:user, school: school)
        UserRole.create!(user: user, role: student_role, school: school)
        StudentClassEnrollment.create!(student: user, school_class: school_class, status: 'pending')
        user.reload
      end
      let(:context) { { current_user: teacher, params: { id: student.id } } }

      before do
        teacher_role
        school_class
        teacher
        student
      end

      it 'succeeds' do
        result = described_class.call(context)
        expect(result).to be_success
      end

      it 'destroys the enrollment' do
        expect do
          described_class.call(context)
        end.to change(StudentClassEnrollment, :count).by(-1)
      end

      it 'does NOT destroy the user' do
        student_id = student.id
        described_class.call(context)
        expect(User.find_by(id: student_id)).to be_present
      end
    end

    context 'when teacher tries to decline student not in their class' do
      let(:other_class) do
        SchoolClass.create!(
          school: school,
          name: '5B',
          year: '2025/2026',
          qr_token: SecureRandom.uuid,
          metadata: {}
        )
      end
      let(:teacher) do
        user = create(:user, school: school)
        UserRole.create!(user: user, role: teacher_role, school: school)
        TeacherClassAssignment.create!(teacher: user, school_class: other_class, role: 'teacher')
        user.reload
      end
      let(:student) do
        user = create(:user, school: school)
        UserRole.create!(user: user, role: student_role, school: school)
        StudentClassEnrollment.create!(student: user, school_class: school_class, status: 'pending')
        user.reload
      end
      let(:context) { { current_user: teacher, params: { id: student.id } } }

      before do
        teacher_role
        school_class
        other_class
        teacher
        student
      end

      it 'fails with authorization error' do
        result = described_class.call(context)
        expect(result).to be_failure
        expect(result.message).to include('Brak uprawnień')
      end
    end

    context 'when student not found' do
      let(:context) { { current_user: school_manager, params: { id: SecureRandom.uuid } } }

      before do
        school_manager
        school_class
      end

      it 'fails' do
        result = described_class.call(context)
        expect(result).to be_failure
        expect(result.message).to include('Uczeń nie został znaleziony')
        expect(result.status).to eq(:not_found)
      end
    end

    context 'when user is not authorized' do
      let(:unauthorized_user) { create(:user, school: school) }
      let(:student) do
        user = create(:user, school: school)
        UserRole.create!(user: user, role: student_role, school: school)
        StudentClassEnrollment.create!(student: user, school_class: school_class, status: 'approved')
        user.reload
      end
      let(:context) { { current_user: unauthorized_user, params: { id: student.id } } }

      before do
        school_class
        student
      end

      it 'fails' do
        result = described_class.call(context)
        expect(result).to be_failure
        expect(result.message).to include('Brak uprawnień')
      end
    end

    context 'when student has no enrollments in this school' do
      let(:student) do
        user = create(:user, school: school)
        UserRole.create!(user: user, role: student_role, school: school)
        # No enrollment created
        user.reload
      end
      let(:context) { { current_user: school_manager, params: { id: student.id } } }

      before do
        school_manager
        school_class
        student
      end

      it 'fails with not found' do
        result = described_class.call(context)
        expect(result).to be_failure
        expect(result.status).to eq(:not_found)
      end
    end
  end
end
