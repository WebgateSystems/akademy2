# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API V1 Teacher Students', type: :request do
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
  let(:token) { Jwt::TokenService.encode({ user_id: teacher.id }) }
  let(:headers) { { 'Authorization' => "Bearer #{token}" } }

  before do
    teacher_role
    student_role
    school_class
  end

  describe 'POST /api/v1/teacher/students' do
    let(:valid_params) do
      {
        student: {
          first_name: 'Jan',
          last_name: 'Kowalski',
          school_class_id: school_class.id,
          password: '1234',
          password_confirmation: '1234'
        }
      }
    end

    it 'returns 201 on success' do
      post '/api/v1/teacher/students', params: valid_params, headers: headers
      expect(response).to have_http_status(:created)
    end

    it 'creates a student' do
      teacher # ensure teacher is created before the expect block
      expect do
        post '/api/v1/teacher/students', params: valid_params, headers: headers
      end.to change(User, :count).by(1)
    end

    it 'returns 401 without token' do
      post '/api/v1/teacher/students', params: valid_params
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 403 for non-teacher' do
      admin_role = Role.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' }
      admin = create(:user, school: school)
      UserRole.create!(user: admin, role: admin_role, school: school)
      admin_token = Jwt::TokenService.encode({ user_id: admin.id })

      post '/api/v1/teacher/students', params: valid_params,
                                       headers: { 'Authorization' => "Bearer #{admin_token}" }
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 422 without PIN' do
      params = { student: { first_name: 'Jan', last_name: 'Kowalski', school_class_id: school_class.id } }
      post '/api/v1/teacher/students', params: params, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH /api/v1/teacher/students/:id' do
    before { student }

    it 'returns 200 on success' do
      patch "/api/v1/teacher/students/#{student.id}",
            params: { student: { first_name: 'Updated' } },
            headers: headers
      expect(response).to have_http_status(:ok)
    end

    it 'updates the student' do
      patch "/api/v1/teacher/students/#{student.id}",
            params: { student: { first_name: 'Updated' } },
            headers: headers
      student.reload
      expect(student.first_name).to eq('Updated')
    end

    it 'returns 404 for student not in teacher class' do
      other_class = SchoolClass.create!(school: school, name: '5B', year: '2025/2026',
                                        qr_token: SecureRandom.uuid, metadata: {})
      other_student = create(:user, school: school)
      UserRole.create!(user: other_student, role: student_role, school: school)
      StudentClassEnrollment.create!(student: other_student, school_class: other_class, status: 'approved')

      patch "/api/v1/teacher/students/#{other_student.id}",
            params: { student: { first_name: 'Hacked' } },
            headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 401 without token' do
      patch "/api/v1/teacher/students/#{student.id}", params: { student: { first_name: 'Updated' } }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'GET /api/v1/teacher/students/:id' do
    before { student }

    it 'returns 200 on success' do
      get "/api/v1/teacher/students/#{student.id}", headers: headers
      expect(response).to have_http_status(:ok)
    end

    it 'returns student data' do
      get "/api/v1/teacher/students/#{student.id}", headers: headers
      json = JSON.parse(response.body)
      expect(json.dig('data', 'data', 'attributes', 'first_name') ||
             json.dig('data', 'attributes', 'first_name')).to eq('Jan')
    end

    it 'returns 404 for student not in teacher class' do
      other_class = SchoolClass.create!(school: school, name: '5B', year: '2025/2026',
                                        qr_token: SecureRandom.uuid, metadata: {})
      other_student = create(:user, school: school)
      UserRole.create!(user: other_student, role: student_role, school: school)
      StudentClassEnrollment.create!(student: other_student, school_class: other_class, status: 'approved')

      get "/api/v1/teacher/students/#{other_student.id}", headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 401 without token' do
      get "/api/v1/teacher/students/#{student.id}"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
