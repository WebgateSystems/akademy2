# frozen_string_literal: true

# rubocop:disable RSpec/ScatteredSetup

require 'swagger_helper'

RSpec.describe 'Teacher School Enrollments API', type: :request do
  let!(:teacher_role) { Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }
  let!(:student_role) { Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' } }

  let(:school) { create(:school) }
  let(:teacher) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: teacher_role, school: school)
    user
  end
  let(:non_teacher) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: student_role, school: school)
    user
  end

  path '/api/v1/teacher/school_enrollments/join' do
    post 'Join a school using join token' do
      tags 'Teacher Enrollments'
      consumes 'application/json'
      produces 'application/json'
      security [] # session-based auth

      parameter name: :payload, in: :body, required: true, schema: {
        type: :object,
        required: %w[token],
        properties: {
          token: { type: :string, description: 'School join token' }
        }
      }

      response '201', 'join request created' do
        before do
          sign_in teacher
          allow(NotificationService).to receive(:create_teacher_enrollment_request)
        end

        schema JSON.parse(
          File.read(Rails.root.join('spec/support/api/schemas/teacher/school_enrollments/join.json'))
        )

        let(:payload) { { token: school.join_token } }

        run_test! do
          expect(response).to match_json_schema('teacher/school_enrollments/join')
          json = JSON.parse(response.body)
          expect(json['status']).to eq('pending')
        end
      end

      response '404', 'school not found' do
        before { sign_in teacher }

        let(:payload) { { token: 'invalid-token' } }

        run_test!
      end

      response '422', 'missing token' do
        before { sign_in teacher }

        let(:payload) { { token: '' } }

        run_test!
      end

      response '422', 'already enrolled' do
        before do
          sign_in teacher
          TeacherSchoolEnrollment.create!(teacher: teacher, school: school, status: 'pending')
        end

        let(:payload) { { token: school.join_token } }

        run_test!
      end

      response '403', 'user is not a teacher' do
        before { sign_in non_teacher }

        let(:payload) { { token: school.join_token } }

        run_test!
      end

      response '401', 'unauthenticated' do
        let(:payload) { { token: school.join_token } }

        run_test!
      end
    end
  end

  path '/api/v1/teacher/school_enrollments/pending' do
    get 'List pending school enrollments' do
      tags 'Teacher Enrollments'
      produces 'application/json'
      security []

      response '200', 'pending enrollments returned' do
        before do
          sign_in teacher
          TeacherSchoolEnrollment.create!(teacher: teacher, school: school, status: 'pending')
        end

        schema JSON.parse(
          File.read(Rails.root.join('spec/support/api/schemas/teacher/school_enrollments/pending.json'))
        )

        run_test! do
          expect(response).to match_json_schema('teacher/school_enrollments/pending')
          json = JSON.parse(response.body)
          expect(json['enrollments'].first['school_name']).to eq(school.name)
        end
      end

      response '200', 'empty list when none pending' do
        before { sign_in teacher }

        schema JSON.parse(
          File.read(Rails.root.join('spec/support/api/schemas/teacher/school_enrollments/pending.json'))
        )

        run_test! do
          expect(response).to match_json_schema('teacher/school_enrollments/pending')
        end
      end

      response '403', 'user is not a teacher' do
        before { sign_in non_teacher }

        run_test!
      end

      response '401', 'unauthenticated' do
        run_test!
      end
    end
  end

  path '/api/v1/teacher/school_enrollments/{id}/cancel' do
    parameter name: :id, in: :path, type: :string, description: 'Enrollment ID', required: true

    delete 'Cancel pending school enrollment' do
      tags 'Teacher Enrollments'
      produces 'application/json'
      security []

      response '200', 'enrollment canceled' do
        let!(:enrollment) do
          TeacherSchoolEnrollment.create!(teacher: teacher, school: school, status: 'pending')
        end

        before do
          sign_in teacher
          allow(NotificationService).to receive(:resolve_teacher_enrollment_request)
        end

        schema JSON.parse(
          File.read(Rails.root.join('spec/support/api/schemas/teacher/school_enrollments/cancel.json'))
        )

        let(:id) { enrollment.id }

        run_test! do
          expect(response).to match_json_schema('teacher/school_enrollments/cancel')
          expect(TeacherSchoolEnrollment.find_by(id: enrollment.id)).to be_nil
        end
      end

      response '404', 'enrollment not found' do
        before { sign_in teacher }

        let(:id) { SecureRandom.uuid }

        run_test!
      end

      response '422', 'enrollment not pending' do
        let!(:enrollment) do
          TeacherSchoolEnrollment.create!(teacher: teacher, school: school, status: 'approved')
        end
        before { sign_in teacher }

        let(:id) { enrollment.id }

        run_test!
      end

      response '404', 'enrollment belongs to another teacher' do
        let!(:other_teacher) do
          user = create(:user, school: school)
          UserRole.create!(user: user, role: teacher_role, school: school)
          user
        end
        let!(:enrollment) do
          TeacherSchoolEnrollment.create!(teacher: other_teacher, school: school, status: 'pending')
        end
        before { sign_in teacher }

        let(:id) { enrollment.id }

        run_test!
      end

      response '403', 'user is not a teacher' do
        let!(:enrollment) do
          TeacherSchoolEnrollment.create!(teacher: teacher, school: school, status: 'pending')
        end
        before { sign_in non_teacher }

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
# rubocop:enable RSpec/ScatteredSetup
