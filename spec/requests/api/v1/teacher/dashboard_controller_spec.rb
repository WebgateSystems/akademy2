# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API Teacher Dashboard', type: :request do
  let!(:teacher_role) { Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }
  let!(:student_role) { Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' } }
  let(:school) { create(:school) }
  let(:teacher) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: teacher_role, school: school)
    user
  end
  let(:token) { Jwt::TokenService.encode({ user_id: teacher.id }, 1.hour.from_now) }
  let(:headers) { { 'Authorization' => "Bearer #{token}" } }

  let(:school_class) do
    SchoolClass.create!(
      school: school,
      name: '4A',
      year: school.current_academic_year_value,
      qr_token: SecureRandom.uuid,
      metadata: {}
    )
  end
  let(:student) do
    user = create(:user, school: school, first_name: 'Jan', last_name: 'Kowalski')
    UserRole.create!(user: user, role: student_role, school: school)
    StudentClassEnrollment.create!(student: user, school_class: school_class)
    user
  end

  before do
    TeacherClassAssignment.create!(teacher: teacher, school_class: school_class, role: 'teacher')
    student
  end

  describe 'GET /api/v1/teacher/dashboard' do
    it 'returns aggregated dashboard data' do
      get api_v1_teacher_dashboard_path, headers: headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data']['teacher']['email']).to eq(teacher.email)
      expect(json['data']['classes']).not_to be_empty
    end

    it 'rejects non-teacher users' do
      user = create(:user, school: school)
      token = Jwt::TokenService.encode({ user_id: user.id }, 1.hour.from_now)

      get api_v1_teacher_dashboard_path, headers: { 'Authorization' => "Bearer #{token}" }

      expect(response).to have_http_status(:forbidden)
      json = JSON.parse(response.body)
      expect(json['error']).to include('teacher access required')
    end
  end

  describe 'GET /api/v1/teacher/dashboard/class/:id' do
    it 'returns class details' do
      get api_v1_teacher_dashboard_class_path(id: school_class.id), headers: headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['data']['class']['name']).to eq('4A')
      expect(json['data']['students'].first['first_name']).to eq('Jan')
    end

    it 'returns 404 when class not assigned to teacher' do
      other_class = SchoolClass.create!(
        school: school,
        name: '5B',
        year: school.current_academic_year_value,
        qr_token: SecureRandom.uuid,
        metadata: {}
      )

      get api_v1_teacher_dashboard_class_path(id: other_class.id), headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end
end
