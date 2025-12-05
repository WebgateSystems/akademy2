# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API Student Events', type: :request do
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

  before do
    StudentClassEnrollment.create!(student: student, school_class: school_class, status: 'approved')
  end

  describe 'POST /api/v1/student/events' do
    it 'logs video_started event' do
      params = {
        event_type: 'video_started',
        content_id: 123,
        learning_module_id: 456
      }

      expect do
        post api_v1_student_events_path, params: params.to_json, headers: headers
      end.to change { Event.where(event_type: 'video_started').count }.by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['success']).to be true

      event = Event.find_by(event_type: 'video_started')
      expect(event.user).to eq(student)
      expect(event.data['content_id']).to eq(123)
    end

    it 'logs video_completed event' do
      params = {
        event_type: 'video_completed',
        content_id: 123,
        duration_sec: 300,
        progress_percent: 100
      }

      post api_v1_student_events_path, params: params.to_json, headers: headers

      expect(response).to have_http_status(:created)
      event = Event.find_by(event_type: 'video_completed')
      expect(event).not_to be_nil
      expect(event.data['duration_sec']).to eq(300)
    end

    it 'logs quiz_started event' do
      params = {
        event_type: 'quiz_started',
        learning_module_id: 789
      }

      post api_v1_student_events_path, params: params.to_json, headers: headers

      expect(response).to have_http_status(:created)
      event = Event.find_by(event_type: 'quiz_started')
      expect(event).not_to be_nil
    end

    it 'logs infographic_viewed event' do
      params = {
        event_type: 'infographic_viewed',
        content_id: 123,
        content_type: 'infographic',
        learning_module_id: 456
      }

      post api_v1_student_events_path, params: params.to_json, headers: headers

      expect(response).to have_http_status(:created)
      event = Event.find_by(event_type: 'infographic_viewed')
      expect(event).not_to be_nil
    end

    it 'rejects invalid event type' do
      params = { event_type: 'invalid_type' }

      post api_v1_student_events_path, params: params.to_json, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['error']).to include('Invalid event type')
    end

    it 'rejects unauthenticated requests' do
      post api_v1_student_events_path, params: { event_type: 'video_started' }.to_json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST /api/v1/student/events/batch' do
    it 'logs multiple events at once' do
      params = {
        events: [
          { event_type: 'video_started', data: { content_id: 1 } },
          { event_type: 'video_completed', data: { content_id: 1 } },
          { event_type: 'quiz_started', data: { learning_module_id: 1 } }
        ]
      }

      expect do
        post batch_api_v1_student_events_path, params: params.to_json, headers: headers
      end.to change { Event.where.not(event_type: 'api_request').count }.by(3)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['logged_count']).to eq(3)
    end

    it 'handles partial failures' do
      params = {
        events: [
          { event_type: 'video_started', data: { content_id: 1 } },
          { event_type: 'invalid_type', data: {} },
          { event_type: 'quiz_started', data: { learning_module_id: 1 } }
        ]
      }

      expect do
        post batch_api_v1_student_events_path, params: params.to_json, headers: headers
      end.to change { Event.where.not(event_type: 'api_request').count }.by(2)

      expect(response).to have_http_status(:multi_status)
      json = JSON.parse(response.body)
      expect(json['logged_count']).to eq(2)
      expect(json['errors']).not_to be_empty
    end

    it 'accepts occurred_at timestamp for offline sync' do
      past_time = 1.hour.ago.iso8601
      params = {
        events: [
          { event_type: 'video_started', data: { content_id: 1 }, occurred_at: past_time, client: 'mobile' }
        ]
      }

      post batch_api_v1_student_events_path, params: params.to_json, headers: headers

      expect(response).to have_http_status(:created)
      event = Event.find_by(event_type: 'video_started')
      expect(event.client).to eq('mobile')
    end

    it 'rejects non-array events parameter' do
      params = { events: 'not an array' }

      post batch_api_v1_student_events_path, params: params.to_json, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
