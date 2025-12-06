# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Users::Registrations', type: :request do
  let(:headers) do
    {
      'Accept' => 'application/json',
      'Content-Type' => 'application/json'
    }
  end

  let(:valid_user_params) do
    {
      user: {
        email: "newuser_#{SecureRandom.hex(4)}@example.com",
        password: 'password123',
        password_confirmation: 'password123',
        first_name: 'John',
        last_name: 'Doe',
        locale: 'en'
      }
    }
  end

  describe 'POST /api/v1/users/registrations' do
    context 'without invite_token' do
      it 'returns 404 not found' do
        post '/api/v1/users/registrations', params: valid_user_params, headers: headers, as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'does not create a user' do
        expect do
          post '/api/v1/users/registrations', params: valid_user_params, headers: headers, as: :json
        end.not_to change(User, :count)
      end
    end

    context 'with blank invite_token' do
      it 'returns 404 not found' do
        post '/api/v1/users/registrations',
             params: valid_user_params.merge(invite_token: ''),
             headers: headers,
             as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'with invalid invite_token' do
      it 'returns 404 not found' do
        post '/api/v1/users/registrations',
             params: valid_user_params.merge(invite_token: 'invalid-token'),
             headers: headers,
             as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'does not create a user' do
        expect do
          post '/api/v1/users/registrations',
               params: valid_user_params.merge(invite_token: 'invalid-token'),
               headers: headers,
               as: :json
        end.not_to change(User, :count)
      end
    end

    # NOTE: Tests for valid invite tokens are covered in the controller spec
    # (spec/controllers/api/v1/users/registrations_controller_spec.rb)
    # which tests the helper methods directly.
    #
    # Full integration testing of the create action with valid tokens requires
    # a real database-backed invite token system rather than the in-memory
    # registry used for testing, as the registry doesn't persist correctly
    # across the request/response boundary in request specs.
  end
end
