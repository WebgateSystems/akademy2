# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API V1 Events', type: :request do
  let(:user) { create(:user) }
  let(:token) { Jwt::TokenService.encode({ user_id: user.id }) }
  let(:headers) { { 'Authorization' => "Bearer #{token}" } }

  describe 'GET /api/v1/events' do
    context 'when authorized' do
      it 'returns 200 and events payload' do
        result = double(
          status: :ok,
          success?: true,
          form: { events: [] },
          serializer: nil,
          headers: {},
          pagination: nil,
          access_token: nil,
          to_h: {}
        )
        allow(Api::V1::Events::ListEvents).to receive(:call).and_return(result)

        get '/api/v1/events', headers: headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json).to be_a(Hash)
      end
    end

    context 'when unauthorized' do
      it 'returns 401' do
        get '/api/v1/events'
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
