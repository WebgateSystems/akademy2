# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API V1 Register Steps', type: :request do
  # Routes:
  # POST /api/v1/register/profile
  # POST /api/v1/register/verify_phone
  # POST /api/v1/register/set_pin
  # POST /api/v1/register/confirm_pin

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

  before do
    twilio_client = instance_double(Twilio::REST::Client)
    messages = instance_double(Twilio::REST::Api::V2010::AccountContext::MessageList)

    allow(messages).to receive(:create).and_return(
      OpenStruct.new(sid: 'SM123', status: 'sent')
    )

    allow(twilio_client).to receive(:messages).and_return(messages)
    allow(Twilio::REST::Client).to receive(:new).and_return(twilio_client)
  end

  shared_examples 'step endpoint' do |path, interactor|
    it 'returns 200 on success' do
      result = success_result(status: :ok, form: { step: path })
      allow(interactor).to receive(:call).and_return(result)

      post "/api/v1/register/#{path}", params: { step: path }
      expect(response).to have_http_status(:ok)
    end

    it 'returns 422 on validation error' do
      result = double(status: :unprocessable_entity, success?: false, message: ['Invalid'])
      allow(interactor).to receive(:call).and_return(result)

      post "/api/v1/register/#{path}", params: { step: path }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'profile step' do
    include_examples 'step endpoint', 'profile', Api::V1::Register::Steps::Profile
  end

  describe 'verify_phone step' do
    include_examples 'step endpoint', 'verify_phone', Api::V1::Register::Steps::VerifyPhone
  end

  describe 'set_pin step' do
    include_examples 'step endpoint', 'set_pin', Api::V1::Register::Steps::SetPin
  end

  describe 'confirm_pin step' do
    it 'returns 200 on success' do
      result = success_result(status: :ok, form: { step: 'confirm_pin' })
      allow(Api::V1::Register::Steps::ConfirmPin).to receive(:call).and_return(result)

      post '/api/v1/register/confirm_pin', params: { step: 'confirm_pin' }
      expect(response).to have_http_status(:ok)
    end

    it 'returns 422 on validation error' do
      result = double(status: :unprocessable_entity, success?: false, message: ['Invalid'])
      allow(Api::V1::Register::Steps::ConfirmPin).to receive(:call).and_return(result)

      post '/api/v1/register/confirm_pin', params: { step: 'confirm_pin' }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
