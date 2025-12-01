# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Management::UpdateStudent do
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
  let(:new_school_class) do
    SchoolClass.create!(
      school: school,
      name: '4B',
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
    user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
    UserRole.create!(user: user, role: student_role, school: school)
    StudentClassEnrollment.create!(student: user, school_class: school_class)
    user
  end

  describe '#call' do
    context 'when user is authorized' do
      let(:context) do
        {
          current_user: school_manager,
          params: {
            id: student.id,
            student: {
              first_name: 'Jan Updated',
              last_name: 'Kowalski Updated',
              metadata: {
                phone: '+48 999 888 777'
              }
            }
          }
        }
      end

      before do
        principal_role
        school_manager_role
        student_role
        school_manager
        school_class
        new_school_class
        student
      end

      it 'succeeds' do
        result = described_class.call(context)
        expect(result).to be_success
      end

      it 'updates student' do
        described_class.call(context)
        student.reload
        expect(student.first_name).to eq('Jan Updated')
        expect(student.last_name).to eq('Kowalski Updated')
      end

      it 'updates class assignment' do
        # Create a new context with school_class_id
        update_context = {
          current_user: school_manager,
          params: {
            id: student.id,
            student: {
              first_name: 'Jan Updated',
              last_name: 'Kowalski Updated',
              school_class_id: new_school_class.id,
              metadata: {
                phone: '+48 999 888 777'
              }
            }
          }
        }
        result = described_class.call(update_context)
        expect(result).to be_success

        student.reload
        old_enrollment = StudentClassEnrollment.find_by(student: student, school_class: school_class)
        new_enrollment = StudentClassEnrollment.find_by(student: student, school_class: new_school_class)
        expect(old_enrollment).to be_nil
        expect(new_enrollment).to be_present
      end

      it 'sets serializer' do
        result = described_class.call(context)
        expect(result.serializer).to eq(StudentSerializer)
      end
    end

    context 'when user is not authorized' do
      let(:admin_role) { Role.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' } }
      let(:admin_user) do
        user = create(:user, school: school)
        UserRole.create!(user: user, role: admin_role, school: school)
        user
      end
      let(:unauthorized_context) do
        {
          current_user: admin_user,
          params: {
            id: student.id,
            student: {
              first_name: 'Jan Updated'
            }
          }
        }
      end

      before do
        principal_role
        school_manager_role
        student_role
        school_class
        student
      end

      it 'fails' do
        result = described_class.call(unauthorized_context)
        expect(result).to be_failure
      end
    end

    context 'with invalid params' do
      let(:context) do
        {
          current_user: school_manager,
          params: {
            id: student.id,
            student: {
              email: 'invalid-email'
            }
          }
        }
      end

      before do
        principal_role
        school_manager_role
        student_role
        school_manager
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
