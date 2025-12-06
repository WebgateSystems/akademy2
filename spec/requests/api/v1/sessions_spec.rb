# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API V1 Sessions', type: :request do
  describe 'POST /api/v1/session' do
    let(:params) { { session: { email: 'test@example.com', password: 'Password1!' } } }

    context 'when credentials are valid' do
      it 'returns 201' do
        result = double(
          status: :created,
          success?: true,
          form: { user: { id: SecureRandom.uuid } },
          serializer: nil,
          headers: {},
          pagination: nil,
          access_token: 'token',
          to_h: {}
        )
        allow(Api::V1::Sessions::CreateSession).to receive(:call).and_return(result)

        post '/api/v1/session', params: params

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json).to include('user')
      end
    end

    context 'when unauthorized' do
      it 'returns 401' do
        result = double(
          status: :unauthorized,
          success?: false,
          message: 'Invalid login'
        )
        allow(Api::V1::Sessions::CreateSession).to receive(:call).and_return(result)

        post '/api/v1/session', params: params

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when validation fails' do
      it 'returns 422' do
        result = double(
          status: :unprocessable_entity,
          success?: false,
          message: ['Email missing']
        )
        allow(Api::V1::Sessions::CreateSession).to receive(:call).and_return(result)

        post '/api/v1/session', params: params

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
