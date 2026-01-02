# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Passwords API', type: :request do
  path '/api/v1/passwords/forgot' do
    post 'Send reset password instructions' do
      tags 'Passwords'
      consumes 'application/json'
      produces 'application/json'

      before do
        allow_any_instance_of(User)
          .to receive(:send_reset_password_instructions)
          .and_return(true)
      end

      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string, example: 'user@example.com' }
        }
      }

      response '200', 'instructions sent (always for existing / non-existing users)' do
        schema type: :object,
               properties: {
                 message: { type: :string }
               }

        let(:user) { create(:user, email: 'user@example.com') }
        let(:payload) { { email: user.email } }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['message']).to be_present
        end
      end

      response '422', 'email is missing' do
        let(:payload) { {} }

        schema type: :object,
               properties: {
                 message: {
                   type: :array,
                   items: { type: :string }
                 }
               }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['errors']).to include('Email is required')
        end
      end
    end
  end
end
