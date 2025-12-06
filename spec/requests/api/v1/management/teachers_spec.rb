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

  describe 'POST /api/v1/management/teachers' do
    it 'returns 201 on success' do
      result = success_result(status: :created)
      allow(Api::V1::Management::CreateTeacher).to receive(:call).and_return(result)

      post '/api/v1/management/teachers', headers: headers
      expect(response).to have_http_status(:created)
    end
  end
end
