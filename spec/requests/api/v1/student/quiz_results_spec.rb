# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API Student Quiz Results', type: :request do
  let!(:student_role) { Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' } }
  let(:school) { create(:school) }
  let(:student) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: student_role, school: school)
    user
  end
  let(:token) { Jwt::TokenService.encode({ user_id: student.id }, 1.hour.from_now) }
  let(:headers) { { 'Authorization' => "Bearer #{token}", 'Content-Type' => 'application/json' } }

  let(:school_class) do
    SchoolClass.create!(
      school: school,
      name: '4A',
      year: school.current_academic_year_value,
      qr_token: SecureRandom.uuid,
      metadata: {}
    )
  end

  let!(:subject_record) { create(:subject, school: nil, title: 'Mathematics') }
  let!(:unit) { create(:unit, subject: subject_record, title: 'Algebra') }
  let!(:learning_module) { create(:learning_module, unit: unit, title: 'Linear Equations', published: true) }

  before do
    StudentClassEnrollment.create!(student: student, school_class: school_class, status: 'approved')
  end

  describe 'POST /api/v1/student/quiz_results' do
    let(:valid_params) do
      {
        learning_module_id: learning_module.id,
        score: 85,
        details: { answers: [1, 2, 3] }
      }
    end

    it 'creates a new quiz result' do
      expect do
        post api_v1_student_quiz_results_path, params: valid_params.to_json, headers: headers
      end.to change(QuizResult, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data']['score']).to eq(85)
      expect(json['data']['passed']).to be true
    end

    it 'marks result as passed when score >= 80' do
      post api_v1_student_quiz_results_path,
           params: { learning_module_id: learning_module.id, score: 80 }.to_json,
           headers: headers

      json = JSON.parse(response.body)
      expect(json['data']['passed']).to be true
    end

    it 'marks result as failed when score < 80' do
      post api_v1_student_quiz_results_path,
           params: { learning_module_id: learning_module.id, score: 79 }.to_json,
           headers: headers

      json = JSON.parse(response.body)
      expect(json['data']['passed']).to be false
      expect(json['data']['message']).to include('80%')
    end

    it 'updates existing result only if score is better' do
      create(:quiz_result, user: student, learning_module: learning_module, score: 90, passed: true)

      expect do
        post api_v1_student_quiz_results_path,
             params: { learning_module_id: learning_module.id, score: 75 }.to_json,
             headers: headers
      end.not_to change(QuizResult, :count)

      # Score should remain 90 (not downgraded)
      expect(QuizResult.last.score).to eq(90)
    end

    it 'updates existing result when new score is better' do
      create(:quiz_result, user: student, learning_module: learning_module, score: 70, passed: false)

      post api_v1_student_quiz_results_path,
           params: { learning_module_id: learning_module.id, score: 85 }.to_json,
           headers: headers

      expect(QuizResult.last.score).to eq(85)
      expect(QuizResult.last.passed).to be true
    end

    it 'logs quiz completion event' do
      post api_v1_student_quiz_results_path, params: valid_params.to_json, headers: headers

      expect(response).to have_http_status(:created)
      event = Event.find_by(event_type: 'quiz_complete')
      expect(event).not_to be_nil
      expect(event.user).to eq(student)
      expect(event.data['score']).to eq(85)
    end

    it 'returns 404 for non-existent module' do
      post api_v1_student_quiz_results_path,
           params: { learning_module_id: 99_999, score: 85 }.to_json,
           headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it 'rejects unauthenticated requests' do
      post api_v1_student_quiz_results_path, params: valid_params.to_json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'GET /api/v1/student/quiz_results' do
    before do
      create(:quiz_result, user: student, learning_module: learning_module, score: 85, passed: true)
    end

    it 'returns all quiz results for student' do
      get api_v1_student_quiz_results_path, headers: headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data'].length).to eq(1)
      expect(json['data'].first['score']).to eq(85)
    end

    it 'includes learning module and subject info' do
      get api_v1_student_quiz_results_path, headers: headers

      json = JSON.parse(response.body)
      result = json['data'].first
      expect(result['learning_module']['title']).to eq('Linear Equations')
      expect(result['subject']['title']).to eq('Mathematics')
    end
  end
end
