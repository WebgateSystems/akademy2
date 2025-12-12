# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API V1 Student Videos', type: :request do
  let!(:student_role) { Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' } }
  let!(:teacher_role) { Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }

  let(:school) { create(:school) }
  let(:academic_year) { school.academic_years.create!(year: '2024/2025', is_current: true, started_at: Date.current) }
  let(:school_class) do
    SchoolClass.create!(name: '1A', school: school, year: academic_year.year, qr_token: SecureRandom.uuid)
  end
  let(:subject_record) { create(:subject, school: school) }

  let(:student) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: student_role, school: school)
    StudentClassEnrollment.create!(student: user, school_class: school_class, status: 'approved')
    user
  end

  let(:other_student) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: student_role, school: school)
    StudentClassEnrollment.create!(student: user, school_class: school_class, status: 'approved')
    user
  end

  let(:teacher) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: teacher_role, school: school)
    user
  end

  let(:token) { Jwt::TokenService.encode({ user_id: student.id }) }
  let(:headers) { { 'Authorization' => "Bearer #{token}" } }

  before do
    academic_year
    school_class
    subject_record
  end

  describe 'GET /api/v1/student/videos' do
    it 'returns 200 with videos list' do
      create(:student_video, :approved, user: other_student, school: school, subject: subject_record)

      get '/api/v1/student/videos', headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data']).to be_an(Array)
    end

    it 'returns 200 with search query parameter q' do
      create(:student_video, :approved, user: other_student, school: school, subject: subject_record,
                                        title: 'Math Tutorial')
      create(:student_video, :approved, user: other_student, school: school, subject: subject_record,
                                        title: 'Science Lesson')

      get '/api/v1/student/videos', params: { q: 'Math' }, headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data']).to be_an(Array)
      expect(json['data'].length).to eq(1)
      expect(json['data'].first['title']).to eq('Math Tutorial')
    end

    it 'searches by author name with q parameter' do
      other_student.update!(first_name: 'Unique', last_name: 'Author')
      create(:student_video, :approved, user: other_student, school: school, subject: subject_record,
                                        title: 'Some Video')

      get '/api/v1/student/videos', params: { q: 'Unique' }, headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data'].length).to eq(1)
    end

    it 'returns empty array when search has no matches' do
      create(:student_video, :approved, user: other_student, school: school, subject: subject_record,
                                        title: 'Math Tutorial')

      get '/api/v1/student/videos', params: { q: 'NonExistent' }, headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data']).to eq([])
      expect(json['meta']['total']).to eq(0)
    end

    it 'returns 401 without token' do
      get '/api/v1/student/videos'

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'GET /api/v1/student/videos/my' do
    it 'returns 200 with own videos' do
      create(:student_video, user: student, school: school, subject: subject_record)

      get '/api/v1/student/videos/my', headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data']).to be_an(Array)
      expect(json['data'].length).to eq(1)
    end

    it 'returns 401 without token' do
      get '/api/v1/student/videos/my'

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'GET /api/v1/student/videos/:id' do
    it 'returns 200 with video details' do
      video = create(:student_video, :approved, user: student, school: school, subject: subject_record,
                                                title: 'Test Video')

      get "/api/v1/student/videos/#{video.id}", headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data']['title']).to eq('Test Video')
    end

    it 'returns 404 when video not found' do
      get '/api/v1/student/videos/00000000-0000-0000-0000-000000000000', headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 401 without token' do
      video = create(:student_video, :approved, user: student, school: school, subject: subject_record)

      get "/api/v1/student/videos/#{video.id}"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'PATCH /api/v1/student/videos/:id' do
    it 'returns 200 when updating own pending video' do
      video = create(:student_video, user: student, school: school, subject: subject_record, title: 'Old Title')

      patch "/api/v1/student/videos/#{video.id}",
            params: { video: { title: 'New Title', description: 'New description' } },
            headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data']['title']).to eq('New Title')
    end

    it 'returns 403 when updating other student video' do
      video = create(:student_video, user: other_student, school: school, subject: subject_record)

      patch "/api/v1/student/videos/#{video.id}",
            params: { video: { title: 'Hacked' } },
            headers: headers

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 422 when updating approved video' do
      video = create(:student_video, :approved, user: student, school: school, subject: subject_record)

      patch "/api/v1/student/videos/#{video.id}",
            params: { video: { title: 'New Title' } },
            headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns 401 without token' do
      video = create(:student_video, user: student, school: school, subject: subject_record)

      patch "/api/v1/student/videos/#{video.id}",
            params: { video: { title: 'New Title' } }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'DELETE /api/v1/student/videos/:id' do
    it 'returns 200 when deleting own pending video' do
      video = create(:student_video, user: student, school: school, subject: subject_record)

      delete "/api/v1/student/videos/#{video.id}", headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(StudentVideo.find_by(id: video.id)).to be_nil
    end

    it 'returns 403 when deleting other student video' do
      video = create(:student_video, user: other_student, school: school, subject: subject_record)

      delete "/api/v1/student/videos/#{video.id}", headers: headers

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 403 when deleting approved video' do
      video = create(:student_video, :approved, user: student, school: school, subject: subject_record)

      delete "/api/v1/student/videos/#{video.id}", headers: headers

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 404 when video not found' do
      delete '/api/v1/student/videos/00000000-0000-0000-0000-000000000000', headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 401 without token' do
      video = create(:student_video, user: student, school: school, subject: subject_record)

      delete "/api/v1/student/videos/#{video.id}"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST /api/v1/student/videos/:id/like' do
    it 'returns 200 when toggling like' do
      video = create(:student_video, :approved, user: other_student, school: school, subject: subject_record)

      post "/api/v1/student/videos/#{video.id}/like", headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
    end

    it 'returns 404 when video not found' do
      post '/api/v1/student/videos/00000000-0000-0000-0000-000000000000/like', headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 401 without token' do
      video = create(:student_video, :approved, user: student, school: school, subject: subject_record)

      post "/api/v1/student/videos/#{video.id}/like"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'GET /api/v1/student/videos/subjects' do
    it 'returns 200 with subjects list' do
      get '/api/v1/student/videos/subjects', headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data']).to be_an(Array)
    end

    it 'returns 401 without token' do
      get '/api/v1/student/videos/subjects'

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
