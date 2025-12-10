# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Student Enrollments API', type: :request do
  let!(:student_role) { Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' } }
  let!(:teacher_role) { Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }

  let(:school) { create(:school) }
  let(:academic_year) { school.academic_years.create!(year: '2024/2025', is_current: true, started_at: Date.current) }
  let(:school_class) do
    SchoolClass.create!(name: '1A', school: school, year: academic_year.year, qr_token: SecureRandom.uuid)
  end

  let(:student) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: student_role, school: school)
    user
  end

  let(:teacher) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: teacher_role, school: school)
    user
  end

  before do
    academic_year
    school_class
  end

  path '/api/v1/student/enrollments/join' do
    post 'Join a class using join token' do
      tags 'Student Enrollments'
      consumes 'application/json'
      produces 'application/json'
      security [] # session-based auth

      parameter name: :payload, in: :body, required: true, schema: {
        type: :object,
        required: %w[token],
        properties: {
          token: { type: :string, description: 'Join token' }
        }
      }

      response '201', 'join request created' do
        before do
          sign_in student
          allow(NotificationService).to receive(:create_student_enrollment_request)
        end

        schema JSON.parse(
          File.read(Rails.root.join('spec/support/api/schemas/student/enrollments/join.json'))
        )

        let(:payload) { { token: school_class.join_token } }

        run_test! do
          json = JSON.parse(response.body)
          expect(json['success']).to be true
          expect(json['status']).to eq('pending')
          expect(response).to match_json_schema('student/enrollments/join')
        end
      end

      response '404', 'class not found' do
        before { sign_in student }

        let(:payload) { { token: 'invalid-token' } }
        run_test!
      end

      response '422', 'missing token' do
        before { sign_in student }

        let(:payload) { { token: '' } }
        run_test!
      end

      response '422', 'already enrolled' do
        before do
          sign_in student
          StudentClassEnrollment.create!(student: student, school_class: school_class, status: 'pending')
        end

        let(:payload) { { token: school_class.join_token } }
        run_test!
      end

      response '403', 'user is not a student' do
        before { sign_in teacher }

        let(:payload) { { token: school_class.join_token } }
        run_test!
      end

      response '401', 'unauthenticated' do
        let(:payload) { { token: school_class.join_token } }
        run_test!
      end
    end
  end

  path '/api/v1/student/enrollments/pending' do
    get 'List pending enrollments' do
      tags 'Student Enrollments'
      produces 'application/json'
      security []

      response '200', 'pending enrollments returned' do
        before do
          sign_in student
          StudentClassEnrollment.create!(student: student, school_class: school_class, status: 'pending')
        end

        schema JSON.parse(
          File.read(Rails.root.join('spec/support/api/schemas/student/enrollments/pending.json'))
        )

        run_test! do
          json = JSON.parse(response.body)
          expect(json['enrollments'].first['class_name']).to eq('1A')
          expect(response).to match_json_schema('student/enrollments/pending')
        end
      end

      response '200', 'empty list when none pending' do
        before { sign_in student }

        schema JSON.parse(
          File.read(Rails.root.join('spec/support/api/schemas/student/enrollments/pending.json'))
        )

        run_test! do
          expect(response).to match_json_schema('student/enrollments/pending')
        end
      end

      response '403', 'user is not a student' do
        before { sign_in teacher }

        run_test!
      end

      response '401', 'unauthenticated' do
        run_test!
      end
    end
  end

  path '/api/v1/student/enrollments/{id}/cancel' do
    parameter name: :id, in: :path, type: :string, description: 'Enrollment ID', required: true

    delete 'Cancel pending enrollment' do
      tags 'Student Enrollments'
      produces 'application/json'
      security []

      response '200', 'enrollment canceled' do
        let!(:enrollment) do
          StudentClassEnrollment.create!(student: student, school_class: school_class, status: 'pending')
        end

        before do
          sign_in student
          allow(NotificationService).to receive(:resolve_student_enrollment_request)
        end

        schema JSON.parse(
          File.read(Rails.root.join('spec/support/api/schemas/student/enrollments/cancel.json'))
        )

        let(:id) { enrollment.id }

        run_test! do
          expect(response).to match_json_schema('student/enrollments/cancel')
          expect(StudentClassEnrollment.find_by(id: enrollment.id)).to be_nil
        end
      end

      response '404', 'enrollment not found' do
        before { sign_in student }

        let(:id) { SecureRandom.uuid }
        run_test!
      end

      response '422', 'enrollment not pending' do
        let!(:enrollment) do
          StudentClassEnrollment.create!(student: student, school_class: school_class, status: 'approved')
        end

        before { sign_in student }

        let(:id) { enrollment.id }
        run_test!
      end

      response '404', 'enrollment belongs to another student' do
        let!(:other_student) do
          user = create(:user, school: school)
          UserRole.create!(user: user, role: student_role, school: school)
          user
        end

        let!(:enrollment) do
          StudentClassEnrollment.create!(student: other_student, school_class: school_class, status: 'pending')
        end

        before { sign_in student }

        let(:id) { enrollment.id }
        run_test!
      end

      response '403', 'user is not a student' do
        let!(:enrollment) do
          StudentClassEnrollment.create!(student: student, school_class: school_class, status: 'pending')
        end

        before { sign_in teacher }

        let(:id) { enrollment.id }
        run_test!
      end

      response '401', 'unauthenticated' do
        let(:id) { SecureRandom.uuid }
        run_test!
      end
    end
  end
end
