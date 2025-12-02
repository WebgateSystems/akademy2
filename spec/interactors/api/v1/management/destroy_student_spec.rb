# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Management::DestroyStudent do
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
  let(:student) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: student_role, school: school)
    StudentClassEnrollment.find_or_create_by!(student: user, school_class: school_class) do |e|
      e.status = 'approved'
    end
    user.reload
  end

  describe '#call' do
    context 'when user is authorized' do
      let(:context) { { current_user: school_manager, params: { id: student.id } } }

      before do
        principal_role
        school_manager_role
        student_role
        school_manager
        school_class
        student
      end

      it 'succeeds' do
        result = described_class.call(context)
        expect(result).to be_success
      end

      it 'destroys student' do
        expect do
          described_class.call(context)
        end.to change(User, :count).by(-1)
      end

      it 'sets no_content status' do
        result = described_class.call(context)
        expect(result.status).to eq(:no_content)
      end
    end

    context 'when user is not authorized' do
      let(:admin_role) { Role.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' } }
      let(:admin_user) do
        user = create(:user, school: school)
        UserRole.create!(user: user, role: admin_role, school: school)
        user
      end
      let(:context) { { current_user: admin_user, params: { id: student.id } } }

      before do
        principal_role
        school_manager_role
        student_role
        school_class
        student
      end

      it 'fails' do
        result = described_class.call(context)
        expect(result).to be_failure
      end
    end

    context 'when student not found' do
      let(:context) { { current_user: school_manager, params: { id: SecureRandom.uuid } } }

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
        expect(result.message).to include('Uczeń nie został znaleziony')
        expect(result.status).to eq(:not_found)
      end
    end

    context 'when teacher tries to destroy student in their class' do
      let(:teacher_role) { Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }
      let(:teacher) do
        user = create(:user, school: school)
        UserRole.create!(user: user, role: teacher_role, school: school)
        TeacherClassAssignment.create!(teacher: user, school_class: school_class, role: 'teacher')
        user.reload
      end
      let(:teacher_student) do
        user = create(:user, school: school)
        UserRole.create!(user: user, role: student_role, school: school)
        StudentClassEnrollment.create!(student: user, school_class: school_class, status: 'approved')
        user.reload
      end
      let(:context) { { current_user: teacher, params: { id: teacher_student.id } } }

      before do
        teacher_role
        student_role
        school_class
        teacher
        teacher_student
      end

      it 'succeeds' do
        result = described_class.call(context)
        expect(result).to be_success
      end

      it 'destroys student' do
        expect do
          described_class.call(context)
        end.to change(User, :count).by(-1)
      end
    end

    context 'when teacher tries to destroy student not in their class' do
      let(:teacher_role) { Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }
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
      let(:context) { { current_user: teacher, params: { id: student.id } } }

      before do
        teacher_role
        student_role
        school_class
        other_class
        student
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
        # Don't create any roles - simulate user with no school access
        user.reload
      end
      let(:context) { { current_user: user_without_school, params: { id: student.id } } }

      before do
        school_class
        student
      end

      it 'fails with authorization error' do
        result = described_class.call(context)
        expect(result).to be_failure
        # When user has no school, authorize! fails first
        expect(result.message).to include('Brak uprawnień')
      end
    end

    context 'when destroy fails due to validation errors' do
      let(:context) { { current_user: school_manager, params: { id: student.id } } }

      before do
        principal_role
        school_manager_role
        student_role
        school_manager
        school_class
        student
        # Mock destroy to return false
        allow_any_instance_of(User).to receive(:destroy).and_return(false)
        allow_any_instance_of(User).to receive(:errors).and_return(
          double(full_messages: ['Cannot destroy student'])
        )
      end

      it 'fails with error messages' do
        result = described_class.call(context)
        expect(result).to be_failure
        expect(result.message).to include('Cannot destroy student')
      end
    end
  end
end
