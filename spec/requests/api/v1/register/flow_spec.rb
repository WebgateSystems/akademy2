require 'swagger_helper'

RSpec.describe 'API Register — Create Flow', type: :request do
  path '/api/v1/register/flow' do
    get 'Create a registration flow session' do
      tags 'Register'
      produces 'application/json'

      response '201', 'Flow created' do
        schema JSON.parse(
          File.read(
            Rails.root.join('spec/support/api/schemas/register/flow.json')
          )
        )

        run_test! do
          json = JSON.parse(response.body)

          expect(response).to match_json_schema('register/flow')

          flow_id = json['data']['id']
          flow = RegistrationFlow.find(flow_id)

          expect(flow).to be_present
          expect(flow.step).to eq('profile')
          expect(flow.expires_at).to be > Time.current
        end
      end
    end
  end
end
