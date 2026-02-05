# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Teacher::ShowStudent do
  let(:teacher_role) { Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }
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
  let(:teacher) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: teacher_role, school: school)
    TeacherClassAssignment.create!(teacher: user, school_class: school_class, role: 'teacher')
    user
  end
  let(:student) do
    user = create(:user, school: school, first_name: 'Jan', last_name: 'Kowalski')
    UserRole.create!(user: user, role: student_role, school: school)
    StudentClassEnrollment.create!(student: user, school_class: school_class, status: 'approved')
    user
  end

  before do
    teacher_role
    student_role
    school_class
    student
  end

  describe '#call' do
    context 'when teacher is authorized and student is in their class' do
      let(:context) do
        {
          current_user: teacher,
          params: { id: student.id }
        }
      end

      it 'succeeds' do
        result = described_class.call(context)
        expect(result).to be_success
      end

      it 'returns student' do
        result = described_class.call(context)
        expect(result.form).to eq(student)
      end

      it 'sets serializer' do
        result = described_class.call(context)
        expect(result.serializer).to eq(StudentSerializer)
      end

      it 'sets status to ok' do
        result = described_class.call(context)
        expect(result.status).to eq(:ok)
      end
    end

    context 'when student is not in teacher class' do
      let(:other_class) do
        SchoolClass.create!(
          school: school,
          name: '5B',
          year: '2025/2026',
          qr_token: SecureRandom.uuid,
          metadata: {}
        )
      end
      let(:other_student) do
        user = create(:user, school: school)
        UserRole.create!(user: user, role: student_role, school: school)
        StudentClassEnrollment.create!(student: user, school_class: other_class, status: 'approved')
        user
      end
      let(:context) do
        {
          current_user: teacher,
          params: { id: other_student.id }
        }
      end

      it 'fails with not found' do
        result = described_class.call(context)
        expect(result).to be_failure
        expect(result.status).to eq(:not_found)
      end
    end

    context 'when user is not a teacher' do
      let(:admin_role) { Role.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' } }
      let(:admin_user) do
        user = create(:user, school: school)
        UserRole.create!(user: user, role: admin_role, school: school)
        user
      end
      let(:context) do
        {
          current_user: admin_user,
          params: { id: student.id }
        }
      end

      it 'fails with unauthorized' do
        result = described_class.call(context)
        expect(result).to be_failure
        expect(result.message).to include('Brak uprawnień')
      end
    end

    context 'when student does not exist' do
      let(:context) do
        {
          current_user: teacher,
          params: { id: SecureRandom.uuid }
        }
      end

      it 'fails with not found' do
        result = described_class.call(context)
        expect(result).to be_failure
        expect(result.status).to eq(:not_found)
      end
    end

    context 'when teacher has no school' do
      let(:teacher_without_school) do
        user = create(:user, school: nil)
        UserRole.create!(user: user, role: teacher_role, school: nil)
        user
      end
      let(:context) do
        {
          current_user: teacher_without_school,
          params: { id: student.id }
        }
      end

      it 'fails with no school error' do
        result = described_class.call(context)
        expect(result).to be_failure
        expect(result.message).to include('Brak przypisanej szkoły')
      end
    end
  end
end
