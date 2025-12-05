# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API Student Dashboard', type: :request do
  let!(:student_role) { Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' } }
  let!(:teacher_role) { Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }
  let(:school) { create(:school) }
  let(:student) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: student_role, school: school)
    user
  end
  let(:token) { Jwt::TokenService.encode({ user_id: student.id }, 1.hour.from_now) }
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

  let!(:subject_record) { create(:subject, school: nil, title: 'Mathematics', order_index: 1) }
  let!(:unit) { create(:unit, subject: subject_record, title: 'Algebra', order_index: 1) }
  let!(:learning_module) do
    create(:learning_module, unit: unit, title: 'Linear Equations', order_index: 1, published: true)
  end

  before do
    # Create contents for learning module
    create(:content, learning_module: learning_module, title: 'Introduction Video',
                     content_type: 'video', order_index: 1)
    create(:content, learning_module: learning_module, title: 'Summary Infographic',
                     content_type: 'infographic', order_index: 2)
    create(:content, learning_module: learning_module, title: 'Quiz',
                     content_type: 'quiz', order_index: 3,
                     payload: { 'questions' => [{ 'question' => 'What is 2+2?', 'answers' => %w[3 4 5] }] })
  end

  before do
    StudentClassEnrollment.create!(student: student, school_class: school_class, status: 'approved')
  end

  describe 'GET /api/v1/student/dashboard' do
    it 'returns dashboard data with subjects and progress' do
      get api_v1_student_dashboard_path, headers: headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data']['student']['email']).to eq(student.email)
      expect(json['data']['subjects']).not_to be_empty
      expect(json['data']['subjects'].first['title']).to eq('Mathematics')
    end

    it 'includes progress information for subjects' do
      create(:quiz_result, user: student, learning_module: learning_module, score: 90, passed: true)

      get api_v1_student_dashboard_path, headers: headers

      json = JSON.parse(response.body)
      subj_data = json['data']['subjects'].find { |s| s['title'] == 'Mathematics' }
      expect(subj_data['completed_modules']).to eq(1)
      expect(subj_data['average_score']).to eq(90)
    end

    it 'rejects non-student users' do
      teacher = create(:user, school: school)
      UserRole.create!(user: teacher, role: teacher_role, school: school)
      teacher_token = Jwt::TokenService.encode({ user_id: teacher.id }, 1.hour.from_now)

      get api_v1_student_dashboard_path, headers: { 'Authorization' => "Bearer #{teacher_token}" }

      expect(response).to have_http_status(:forbidden)
      json = JSON.parse(response.body)
      expect(json['error']).to include('Student access required')
    end

    it 'rejects unauthenticated requests' do
      get api_v1_student_dashboard_path

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'GET /api/v1/student/subjects/:id' do
    it 'returns subject details with modules' do
      get api_v1_student_subject_path(id: subject_record.id), headers: headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data']['subject']['title']).to eq('Mathematics')
      expect(json['data']['units']).not_to be_empty
      expect(json['data']['units'].first['modules']).not_to be_empty
    end

    it 'includes module completion status' do
      create(:quiz_result, user: student, learning_module: learning_module, score: 85, passed: true)

      get api_v1_student_subject_path(id: subject_record.id), headers: headers

      json = JSON.parse(response.body)
      module_data = json['data']['units'].first['modules'].first
      expect(module_data['completed']).to be true
      expect(module_data['score']).to eq(85)
    end

    it 'returns 404 for non-existent subject' do
      get api_v1_student_subject_path(id: 99_999), headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET /api/v1/student/learning_modules/:id' do
    it 'returns module with contents' do
      get api_v1_student_learning_module_path(id: learning_module.id), headers: headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data']['module']['title']).to eq('Linear Equations')
      expect(json['data']['contents'].length).to eq(3)
    end

    it 'includes quiz questions' do
      get api_v1_student_learning_module_path(id: learning_module.id), headers: headers

      json = JSON.parse(response.body)
      expect(json['data']['quiz']).not_to be_nil
      expect(json['data']['quiz']['questions']).not_to be_empty
    end

    it 'includes previous quiz result if exists' do
      create(:quiz_result, user: student, learning_module: learning_module, score: 75, passed: false)

      get api_v1_student_learning_module_path(id: learning_module.id), headers: headers

      json = JSON.parse(response.body)
      expect(json['data']['previous_result']['score']).to eq(75)
      expect(json['data']['previous_result']['passed']).to be false
    end

    it 'returns 404 for non-existent module' do
      get api_v1_student_learning_module_path(id: 99_999), headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
