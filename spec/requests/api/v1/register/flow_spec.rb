require 'swagger_helper'

RSpec.describe 'API Register — Create Flow', type: :request do
  path '/api/v1/register/flow' do
    get 'Create a registration flow session' do
      tags 'Register'
      produces 'application/json'

      # -----------------------------
      # QUERY PARAMS
      # -----------------------------

      parameter name: :role_key,
                in: :query,
                type: :string,
                required: false,
                description: 'User role (student or teacher) by default role key = student',
                enum: %w[student teacher]

      parameter name: :class_token,
                in: :query,
                type: :string,
                required: false,
                description: 'Token for joining a class'

      parameter name: :join_token,
                in: :query,
                type: :string,
                required: false,
                description: 'Invitation token'

      # -----------------------------
      # RESPONSE
      # -----------------------------

      response '201', 'Flow created' do
        schema JSON.parse(
          File.read(
            Rails.root.join('spec/support/api/schemas/register/flow.json')
          )
        )

        let(:role_key) { 'student' }
        let(:class_token) { 'class_123' }
        let(:join_token) { 'invite_456' }

        run_test! do
          json = JSON.parse(response.body)

          expect(response).to match_json_schema('register/flow')

          flow_id = json.dig('data', 'id')
          flow = RegistrationFlow.find(flow_id)

          expect(flow).to be_present
          expect(flow.step).to eq('profile')
          expect(flow.expires_at).to be > Time.current
        end
      end
    end
  end
end
