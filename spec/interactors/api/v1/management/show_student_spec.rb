# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Management::ShowStudent do
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
    StudentClassEnrollment.create!(student: user, school_class: school_class)
    user
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

      it 'returns student' do
        result = described_class.call(context)
        expect(result.form.id).to eq(student.id)
      end

      it 'sets serializer' do
        result = described_class.call(context)
        expect(result.serializer).to eq(StudentSerializer)
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
      end

      it 'sets not found status' do
        result = described_class.call(context)
        expect(result.status).to eq(:not_found)
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
  end
end
