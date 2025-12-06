# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API V1 Teacher Videos', type: :request do
  let(:school) { create(:school) }
  let(:teacher_role) { Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }
  let(:student_role) { Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' } }
  let(:teacher) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: teacher_role, school: school)
    user
  end
  let(:student) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: student_role, school: school)
    user
  end
  let(:school_class) { create(:school_class, school: school) }
  let!(:teacher_assignment) { create(:teacher_class_assignment, teacher: teacher, school_class: school_class) }
  let!(:enrollment) do
    create(:student_class_enrollment, student: student, school_class: school_class, status: 'approved')
  end
  let(:subject_record) { create(:subject, school: school) }
  let!(:video) do
    create(:student_video,
           user: student,
           school: school,
           subject: subject_record,
           status: 'pending')
  end

  let(:token) { Jwt::TokenService.encode({ user_id: teacher.id }) }
  let(:headers) { { 'Authorization' => "Bearer #{token}" } }

  describe 'GET /api/v1/teacher/videos' do
    it 'returns videos for moderation' do
      get '/api/v1/teacher/videos', headers: headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']).to be_an(Array)
      expect(json['data'].first['id']).to eq(video.id)
    end

    it 'requires auth' do
      get '/api/v1/teacher/videos'
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'GET /api/v1/teacher/videos/:id' do
    it 'returns video details' do
      get "/api/v1/teacher/videos/#{video.id}", headers: headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']['id']).to eq(video.id)
    end

    it 'returns 404 when not found' do
      get "/api/v1/teacher/videos/#{SecureRandom.uuid}", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'PUT /api/v1/teacher/videos/:id/approve' do
    it 'approves pending video' do
      put "/api/v1/teacher/videos/#{video.id}/approve", headers: headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']['status']).to eq('approved')
    end
  end

  describe 'PUT /api/v1/teacher/videos/:id/reject' do
    it 'rejects pending video with reason' do
      put "/api/v1/teacher/videos/#{video.id}/reject", params: { reason: 'Not good' }, headers: headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']['status']).to eq('rejected')
      expect(json['data']['rejection_reason']).to eq('Not good')
    end
  end

  describe 'PATCH /api/v1/teacher/videos/:id' do
    it 'updates video fields' do
      patch "/api/v1/teacher/videos/#{video.id}", params: { video: { title: 'New Title' } }, headers: headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']['title']).to eq('New Title')
    end
  end

  describe 'DELETE /api/v1/teacher/videos/:id' do
    it 'deletes video' do
      delete "/api/v1/teacher/videos/#{video.id}", headers: headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
    end
  end

  describe 'authorization' do
    it 'returns 403 for non-teacher' do
      non_teacher = create(:user, school: school)
      token_other = Jwt::TokenService.encode({ user_id: non_teacher.id })
      get '/api/v1/teacher/videos', headers: { 'Authorization' => "Bearer #{token_other}" }
      expect(response).to have_http_status(:forbidden)
    end
  end
end
