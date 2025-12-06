# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API V1 Register Flows', type: :request do
  # Route: GET /api/v1/register/flow => FlowsController#create (non-standard)

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

  describe 'GET /api/v1/register/flow' do
    it 'returns 201 created flow' do
      result = success_result(status: :created, form: { id: SecureRandom.uuid })
      allow(Api::V1::Register::Flows::Create).to receive(:call).and_return(result)

      get '/api/v1/register/flow'
      expect(response).to have_http_status(:created)
    end

    it 'returns 422 on failure' do
      result = double(status: :unprocessable_entity, success?: false, message: ['Invalid'])
      allow(Api::V1::Register::Flows::Create).to receive(:call).and_return(result)

      get '/api/v1/register/flow'
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
