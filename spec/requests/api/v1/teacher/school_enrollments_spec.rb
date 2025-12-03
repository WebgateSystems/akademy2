# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Teacher::SchoolEnrollments', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:teacher_role) { Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }
  let(:school_manager_role) { Role.find_or_create_by!(key: 'school_manager') { |r| r.name = 'School Manager' } }
  let(:school) { create(:school) }
  let(:teacher) do
    user = create(:user, school: nil, confirmed_at: Time.current)
    UserRole.create!(user: user, role: teacher_role, school: nil)
    user
  end

  before do
    teacher_role
    school_manager_role
  end

  describe 'POST /api/v1/teacher/school_enrollments/join' do
    context 'when authenticated as teacher' do
      before { sign_in teacher }

      context 'with valid token' do
        it 'creates a pending enrollment' do
          expect do
            post '/api/v1/teacher/school_enrollments/join', params: {
              token: school.join_token
            }

            expect(response).to have_http_status(:created)
          end.to change(TeacherSchoolEnrollment, :count).by(1)
        end

        it 'returns success message' do
          post '/api/v1/teacher/school_enrollments/join', params: {
            token: school.join_token
          }

          json = JSON.parse(response.body)
          expect(json['message']).to include('Wniosek')
        end

        it 'creates notification for school managers' do
          # Create a school manager to receive the notification
          manager = create(:user, school: school)
          UserRole.create!(user: manager, role: school_manager_role, school: school)

          expect do
            post '/api/v1/teacher/school_enrollments/join', params: {
              token: school.join_token
            }
          end.to change(Notification, :count).by(1)
        end
      end

      context 'with invalid token' do
        it 'returns error' do
          post '/api/v1/teacher/school_enrollments/join', params: {
            token: 'invalid-token'
          }

          expect(response).to have_http_status(:not_found)
        end
      end

      context 'when enrollment already exists' do
        before do
          TeacherSchoolEnrollment.create!(
            teacher: teacher,
            school: school,
            status: 'pending'
          )
        end

        it 'returns error' do
          post '/api/v1/teacher/school_enrollments/join', params: {
            token: school.join_token
          }

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe 'GET /api/v1/teacher/school_enrollments/pending' do
    context 'when authenticated as teacher' do
      before { sign_in teacher }

      context 'when teacher has pending enrollment' do
        let!(:enrollment) do
          TeacherSchoolEnrollment.create!(
            teacher: teacher,
            school: school,
            status: 'pending'
          )
        end

        it 'returns pending enrollment data' do
          get '/api/v1/teacher/school_enrollments/pending'

          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['enrollments']).to be_present
          expect(json['enrollments'].first['id']).to eq(enrollment.id)
        end
      end

      context 'when teacher has no pending enrollment' do
        it 'returns empty enrollments array' do
          get '/api/v1/teacher/school_enrollments/pending'

          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['enrollments']).to be_empty
        end
      end
    end
  end

  describe 'DELETE /api/v1/teacher/school_enrollments/:id/cancel' do
    context 'when authenticated as teacher' do
      before { sign_in teacher }

      let!(:enrollment) do
        TeacherSchoolEnrollment.create!(
          teacher: teacher,
          school: school,
          status: 'pending'
        )
      end

      it 'cancels the enrollment' do
        expect do
          delete "/api/v1/teacher/school_enrollments/#{enrollment.id}/cancel"
        end.to change(TeacherSchoolEnrollment, :count).by(-1)

        expect(response).to have_http_status(:ok)
      end

      context 'when enrollment belongs to another teacher' do
        let(:other_teacher) do
          user = create(:user, school: nil, confirmed_at: Time.current)
          UserRole.create!(user: user, role: teacher_role, school: nil)
          user
        end
        let!(:other_enrollment) do
          TeacherSchoolEnrollment.create!(
            teacher: other_teacher,
            school: school,
            status: 'pending'
          )
        end

        it 'returns not found' do
          delete "/api/v1/teacher/school_enrollments/#{other_enrollment.id}/cancel"

          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
