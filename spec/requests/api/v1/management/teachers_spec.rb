# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API V1 Management Teachers', type: :request do
  let(:manager_role) { Role.find_or_create_by!(key: 'school_manager') { |r| r.name = 'School Manager' } }
  let(:school) { create(:school) }
  let(:manager) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: manager_role, school: school)
    user
  end
  let(:token) { Jwt::TokenService.encode({ user_id: manager.id }) }
  let(:headers) { { 'Authorization' => "Bearer #{token}" } }

  def success_result(status: :ok, form: { data: {} })
    double(
      status: status,
      success?: true,
      form: form,
      serializer: nil,
      headers: {},
      pagination: nil,
      access_token: nil,
      to_h: {}
    )
  end

  describe 'GET /api/v1/management/teachers' do
    it 'returns 200' do
      allow(Api::V1::Management::ListTeachers).to receive(:call).and_return(success_result)
      get '/api/v1/management/teachers', headers: headers
      expect(response).to have_http_status(:ok)
    end

    it 'returns 401 without token' do
      get '/api/v1/management/teachers'
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 403 when forbidden' do
      result = double(status: :forbidden, success?: false, message: ['forbidden'])
      allow(Api::V1::Management::ListTeachers).to receive(:call).and_return(result)
      get '/api/v1/management/teachers', headers: headers
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /api/v1/management/teachers/:id' do
    it 'returns 200' do
      allow(Api::V1::Management::ShowTeacher).to receive(:call).and_return(success_result)
      get '/api/v1/management/teachers/123', headers: headers
      expect(response).to have_http_status(:ok)
    end

    it 'returns 404 when not found' do
      result = double(status: :not_found, success?: false, message: ['Not found'])
      allow(Api::V1::Management::ShowTeacher).to receive(:call).and_return(result)
      get '/api/v1/management/teachers/invalid', headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 401 without token' do
      get '/api/v1/management/teachers/123'
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST /api/v1/management/teachers' do
    it 'returns 201 on success' do
      result = success_result(status: :created)
      allow(Api::V1::Management::CreateTeacher).to receive(:call).and_return(result)

      post '/api/v1/management/teachers', headers: headers
      expect(response).to have_http_status(:created)
    end

    it 'returns 422 on validation error' do
      result = double(status: :unprocessable_entity, success?: false, message: ['Error'])
      allow(Api::V1::Management::CreateTeacher).to receive(:call).and_return(result)

      post '/api/v1/management/teachers', headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns 401 without token' do
      post '/api/v1/management/teachers'
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'PATCH /api/v1/management/teachers/:id' do
    it 'returns 200 on success' do
      allow(Api::V1::Management::UpdateTeacher).to receive(:call).and_return(success_result)
      patch '/api/v1/management/teachers/123', headers: headers
      expect(response).to have_http_status(:ok)
    end

    it 'returns 404 when not found' do
      result = double(status: :not_found, success?: false, message: ['Not found'])
      allow(Api::V1::Management::UpdateTeacher).to receive(:call).and_return(result)
      patch '/api/v1/management/teachers/invalid', headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 401 without token' do
      patch '/api/v1/management/teachers/123'
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'DELETE /api/v1/management/teachers/:id' do
    it 'returns 204 on success' do
      result = success_result(status: :no_content)
      allow(Api::V1::Management::DestroyTeacher).to receive(:call).and_return(result)
      delete '/api/v1/management/teachers/123', headers: headers
      expect(response).to have_http_status(:no_content)
    end

    it 'returns 404 when not found' do
      result = double(status: :not_found, success?: false, message: ['Not found'])
      allow(Api::V1::Management::DestroyTeacher).to receive(:call).and_return(result)
      delete '/api/v1/management/teachers/invalid', headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 401 without token' do
      delete '/api/v1/management/teachers/123'
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST /api/v1/management/teachers/:id/resend_invite' do
    it 'returns 200 on success' do
      allow(Api::V1::Management::ResendInviteTeacher).to receive(:call).and_return(success_result)
      post '/api/v1/management/teachers/123/resend_invite', headers: headers
      expect(response).to have_http_status(:ok)
    end

    it 'returns 404 when not found' do
      result = double(status: :not_found, success?: false, message: ['Not found'])
      allow(Api::V1::Management::ResendInviteTeacher).to receive(:call).and_return(result)
      post '/api/v1/management/teachers/invalid/resend_invite', headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 401 without token' do
      post '/api/v1/management/teachers/123/resend_invite'
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST /api/v1/management/teachers/:id/lock' do
    it 'returns 200 on success' do
      allow(Api::V1::Management::LockTeacher).to receive(:call).and_return(success_result)
      post '/api/v1/management/teachers/123/lock', headers: headers
      expect(response).to have_http_status(:ok)
    end

    it 'returns 404 when not found' do
      result = double(status: :not_found, success?: false, message: ['Not found'])
      allow(Api::V1::Management::LockTeacher).to receive(:call).and_return(result)
      post '/api/v1/management/teachers/invalid/lock', headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 401 without token' do
      post '/api/v1/management/teachers/123/lock'
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST /api/v1/management/teachers/:id/approve' do
    it 'returns 200 on success' do
      allow(Api::V1::Management::ApproveTeacher).to receive(:call).and_return(success_result)
      post '/api/v1/management/teachers/123/approve', headers: headers
      expect(response).to have_http_status(:ok)
    end

    it 'returns 404 when not found' do
      result = double(status: :not_found, success?: false, message: ['Not found'])
      allow(Api::V1::Management::ApproveTeacher).to receive(:call).and_return(result)
      post '/api/v1/management/teachers/invalid/approve', headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 401 without token' do
      post '/api/v1/management/teachers/123/approve'
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST /api/v1/management/teachers/:id/decline' do
    it 'returns 204 on success' do
      result = success_result(status: :no_content)
      allow(Api::V1::Management::DestroyTeacher).to receive(:call).and_return(result)
      post '/api/v1/management/teachers/123/decline', headers: headers
      expect(response).to have_http_status(:no_content)
    end

    it 'returns 404 when not found' do
      result = double(status: :not_found, success?: false, message: ['Not found'])
      allow(Api::V1::Management::DestroyTeacher).to receive(:call).and_return(result)
      post '/api/v1/management/teachers/invalid/decline', headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 401 without token' do
      post '/api/v1/management/teachers/123/decline'
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
