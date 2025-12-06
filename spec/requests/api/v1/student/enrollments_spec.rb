# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API V1 Student Enrollments', type: :request do
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

  describe 'POST /api/v1/student/enrollments/join' do
    context 'when student is authenticated' do
      before { sign_in student }

      it 'returns 201 when joining with valid token' do
        allow(NotificationService).to receive(:create_student_enrollment_request)

        post '/api/v1/student/enrollments/join', params: { token: school_class.join_token }

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['class_name']).to eq('1A')
        expect(json['status']).to eq('pending')
      end

      it 'returns 422 when token is missing' do
        post '/api/v1/student/enrollments/join', params: { token: '' }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to include('Token')
      end

      it 'returns 404 when token is invalid' do
        post '/api/v1/student/enrollments/join', params: { token: 'invalid-token' }

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to be_present
      end

      it 'returns 422 when already enrolled' do
        StudentClassEnrollment.create!(student: student, school_class: school_class, status: 'pending')

        post '/api/v1/student/enrollments/join', params: { token: school_class.join_token }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to include('zapisany')
      end
    end

    context 'when user is not a student' do
      before { sign_in teacher }

      it 'returns 403 forbidden' do
        post '/api/v1/student/enrollments/join', params: { token: school_class.join_token }

        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json['error']).to include('uczniowie')
      end
    end

    context 'when not authenticated' do
      it 'returns 401 unauthorized' do
        post '/api/v1/student/enrollments/join', params: { token: school_class.join_token }

        expect(response).to have_http_status(:unauthorized).or redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /api/v1/student/enrollments/pending' do
    context 'when student is authenticated' do
      before { sign_in student }

      it 'returns 200 with pending enrollments' do
        enrollment = StudentClassEnrollment.create!(student: student, school_class: school_class, status: 'pending')

        get '/api/v1/student/enrollments/pending'

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['enrollments']).to be_an(Array)
        expect(json['enrollments'].length).to eq(1)
        expect(json['enrollments'].first['id']).to eq(enrollment.id)
        expect(json['enrollments'].first['class_name']).to eq('1A')
      end

      it 'returns empty array when no pending enrollments' do
        get '/api/v1/student/enrollments/pending'

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['enrollments']).to eq([])
      end
    end

    context 'when user is not a student' do
      before { sign_in teacher }

      it 'returns 403 forbidden' do
        get '/api/v1/student/enrollments/pending'

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'DELETE /api/v1/student/enrollments/:id/cancel' do
    context 'when student is authenticated' do
      before { sign_in student }

      it 'returns 200 when canceling pending enrollment' do
        enrollment = StudentClassEnrollment.create!(student: student, school_class: school_class, status: 'pending')
        allow(NotificationService).to receive(:resolve_student_enrollment_request)

        delete "/api/v1/student/enrollments/#{enrollment.id}/cancel"

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(StudentClassEnrollment.find_by(id: enrollment.id)).to be_nil
      end

      it 'returns 404 when enrollment not found' do
        delete '/api/v1/student/enrollments/00000000-0000-0000-0000-000000000000/cancel'

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to be_present
      end

      it 'returns 422 when enrollment is not pending' do
        enrollment = StudentClassEnrollment.create!(student: student, school_class: school_class, status: 'approved')

        delete "/api/v1/student/enrollments/#{enrollment.id}/cancel"

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to include('oczekujące')
      end

      it 'returns 404 when trying to cancel another student enrollment' do
        other_student = create(:user, school: school)
        UserRole.create!(user: other_student, role: student_role, school: school)
        enrollment = StudentClassEnrollment.create!(student: other_student, school_class: school_class,
                                                    status: 'pending')

        delete "/api/v1/student/enrollments/#{enrollment.id}/cancel"

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when user is not a student' do
      before { sign_in teacher }

      it 'returns 403 forbidden' do
        enrollment = StudentClassEnrollment.create!(student: student, school_class: school_class, status: 'pending')

        delete "/api/v1/student/enrollments/#{enrollment.id}/cancel"

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
