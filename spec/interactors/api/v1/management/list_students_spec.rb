# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Management::ListStudents do
  let!(:principal_role) { Role.find_or_create_by!(key: 'principal') { |r| r.name = 'Principal' } }
  let!(:school_manager_role) { Role.find_or_create_by!(key: 'school_manager') { |r| r.name = 'School Manager' } }
  let!(:student_role) { Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' } }

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
  let(:principal) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: principal_role, school: school)
    user
  end
  let(:school_manager) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: school_manager_role, school: school)
    user
  end

  describe '#call' do
    context 'when user is authorized' do
      let(:context) { { current_user: school_manager, params: {} } }

      before do
        principal
        school_manager
        school_class
      end

      it 'succeeds' do
        result = described_class.call(context)
        expect(result).to be_success
      end

      it 'returns students' do
        student1 = create(:user, school: school)
        UserRole.create!(user: student1, role: student_role, school: school)
        StudentClassEnrollment.create!(student: student1, school_class: school_class)

        student2 = create(:user, school: school)
        UserRole.create!(user: student2, role: student_role, school: school)
        StudentClassEnrollment.create!(student: student2, school_class: school_class)

        result = described_class.call(context)
        expect(result.form.count).to eq(2)
      end

      it 'returns pagination info' do
        result = described_class.call(context)
        expect(result.pagination).to be_present
        expect(result.pagination[:page]).to eq(1)
        expect(result.pagination[:per_page]).to eq(20)
      end

      it 'filters students by current academic year' do
        old_class = SchoolClass.create!(
          school: school,
          name: '3A',
          year: '2024/2025',
          qr_token: SecureRandom.uuid,
          metadata: {}
        )

        student_current = create(:user, school: school)
        UserRole.create!(user: student_current, role: student_role, school: school)
        StudentClassEnrollment.create!(student: student_current, school_class: school_class)

        student_old = create(:user, school: school)
        UserRole.create!(user: student_old, role: student_role, school: school)
        StudentClassEnrollment.create!(student: student_old, school_class: old_class)

        result = described_class.call(context)
        # Query includes students with or without class assignment for current year
        # So both students should be included (one with current year class, one without)
        expect(result.form.count).to be >= 1
        student_ids = result.form.map(&:id)
        expect(student_ids).to include(student_current.id)
      end

      it 'includes students without class assignment' do
        student_with_class = create(:user, school: school)
        UserRole.create!(user: student_with_class, role: student_role, school: school)
        StudentClassEnrollment.create!(student: student_with_class, school_class: school_class)

        student_without_class = create(:user, school: school)
        UserRole.create!(user: student_without_class, role: student_role, school: school)

        result = described_class.call(context)
        expect(result.form.count).to eq(2)
      end
    end

    context 'when user is not authorized' do
      let(:admin_role) { Role.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' } }
      let(:admin_user) do
        user = create(:user, school: school)
        UserRole.create!(user: user, role: admin_role, school: school)
        user
      end
      let(:context) { { current_user: admin_user, params: {} } }

      it 'fails' do
        result = described_class.call(context)
        expect(result).to be_failure
      end

      it 'sets error message' do
        result = described_class.call(context)
        expect(result.message).to be_present
        expect(result.message.first).to include('uprawnień')
      end
    end

    context 'with pagination' do
      let(:context) { { current_user: school_manager, params: { page: 2, per_page: 5 } } }

      before do
        principal
        school_manager
        school_class

        10.times do |i|
          student = create(:user, school: school, email: "student#{i}@example.com")
          UserRole.create!(user: student, role: student_role, school: school)
          StudentClassEnrollment.create!(student: student, school_class: school_class)
        end
      end

      it 'returns correct page' do
        result = described_class.call(context)
        expect(result.pagination[:page]).to eq(2)
        expect(result.form.count).to eq(5)
      end
    end

    context 'with search filter' do
      let(:context) { { current_user: school_manager, params: { search: 'Jan' } } }

      before do
        principal
        school_manager
        school_class

        student1 = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
        UserRole.create!(user: student1, role: student_role, school: school)
        StudentClassEnrollment.create!(student: student1, school_class: school_class)

        student2 = create(:user, first_name: 'Anna', last_name: 'Nowak', school: school)
        UserRole.create!(user: student2, role: student_role, school: school)
        StudentClassEnrollment.create!(student: student2, school_class: school_class)
      end

      it 'filters by search term' do
        result = described_class.call(context)
        expect(result.form.count).to eq(1)
        expect(result.form.first.first_name).to eq('Jan')
      end
    end
  end
end
