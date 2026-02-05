# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Teacher::CreateStudent do
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

  before do
    teacher_role
    student_role
    school_class
  end

  describe '#call' do
    context 'when teacher is authorized and has class access' do
      let(:context) do
        {
          current_user: teacher,
          params: {
            student: {
              first_name: 'Jan',
              last_name: 'Kowalski',
              school_class_id: school_class.id,
              password: '1234',
              password_confirmation: '1234'
            }
          }
        }
      end

      it 'succeeds' do
        result = described_class.call(context)
        expect(result).to be_success
      end

      it 'creates student' do
        teacher # ensure teacher is created before the expect block
        expect { described_class.call(context) }.to change(User, :count).by(1)
      end

      it 'assigns student role' do
        result = described_class.call(context)
        student = result.form
        expect(student.roles.pluck(:key)).to include('student')
      end

      it 'assigns student to school' do
        result = described_class.call(context)
        student = result.form
        expect(student.school_id).to eq(school.id)
      end

      it 'creates approved enrollment' do
        result = described_class.call(context)
        student = result.form
        enrollment = StudentClassEnrollment.find_by(student: student, school_class: school_class)
        expect(enrollment).to be_present
        expect(enrollment.status).to eq('approved')
      end

      it 'confirms student account' do
        result = described_class.call(context)
        student = result.form
        expect(student.confirmed_at).to be_present
      end

      it 'sets serializer' do
        result = described_class.call(context)
        expect(result.serializer).to eq(StudentSerializer)
      end

      it 'sets status to created' do
        result = described_class.call(context)
        expect(result.status).to eq(:created)
      end
    end

    context 'when email is not provided' do
      let(:context) do
        {
          current_user: teacher,
          params: {
            student: {
              first_name: 'Jan',
              last_name: 'Kowalski',
              school_class_id: school_class.id,
              password: '1234',
              password_confirmation: '1234'
            }
          }
        }
      end

      it 'generates email automatically' do
        result = described_class.call(context)
        expect(result).to be_success
        expect(result.form.email).to match(/jan\.kowalski.*@#{school.slug}\.akademy\.pl/)
      end
    end

    context 'when phone is not provided' do
      let(:context) do
        {
          current_user: teacher,
          params: {
            student: {
              first_name: 'Jan',
              last_name: 'Kowalski',
              school_class_id: school_class.id,
              password: '1234',
              password_confirmation: '1234'
            }
          }
        }
      end

      it 'generates phone automatically' do
        result = described_class.call(context)
        expect(result).to be_success
        expect(result.form.metadata['phone']).to match(/\+48\d{9}/)
      end
    end

    context 'when PIN is not provided' do
      let(:context) do
        {
          current_user: teacher,
          params: {
            student: {
              first_name: 'Jan',
              last_name: 'Kowalski',
              school_class_id: school_class.id
            }
          }
        }
      end

      it 'fails with error' do
        result = described_class.call(context)
        expect(result).to be_failure
        expect(result.message).to include('PIN jest wymagany')
      end
    end

    context 'when teacher does not have class access' do
      let(:other_class) do
        SchoolClass.create!(
          school: school,
          name: '5B',
          year: '2025/2026',
          qr_token: SecureRandom.uuid,
          metadata: {}
        )
      end
      let(:context) do
        {
          current_user: teacher,
          params: {
            student: {
              first_name: 'Jan',
              last_name: 'Kowalski',
              school_class_id: other_class.id,
              password: '1234',
              password_confirmation: '1234'
            }
          }
        }
      end

      it 'fails with error' do
        result = described_class.call(context)
        expect(result).to be_failure
        expect(result.message).to include('Brak dostępu do tej klasy')
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
          params: {
            student: {
              first_name: 'Jan',
              last_name: 'Kowalski',
              school_class_id: school_class.id,
              password: '1234',
              password_confirmation: '1234'
            }
          }
        }
      end

      it 'fails' do
        result = described_class.call(context)
        expect(result).to be_failure
        expect(result.message).to include('Brak uprawnień')
      end
    end

    context 'when school_class_id is not provided' do
      let(:context) do
        {
          current_user: teacher,
          params: {
            student: {
              first_name: 'Jan',
              last_name: 'Kowalski',
              password: '1234',
              password_confirmation: '1234'
            }
          }
        }
      end

      it 'fails with error' do
        result = described_class.call(context)
        expect(result).to be_failure
        expect(result.message).to include('Nie podano klasy')
      end
    end

    context 'with email collision' do
      let(:context) do
        {
          current_user: teacher,
          params: {
            student: {
              first_name: 'Jan',
              last_name: 'Kowalski',
              school_class_id: school_class.id,
              password: '1234',
              password_confirmation: '1234'
            }
          }
        }
      end

      before do
        create(:user, email: "jan.kowalski@#{school.slug}.akademy.pl")
      end

      it 'generates unique email with counter' do
        result = described_class.call(context)
        expect(result).to be_success
        expect(result.form.email).to eq("jan.kowalski1@#{school.slug}.akademy.pl")
      end
    end
  end
end
