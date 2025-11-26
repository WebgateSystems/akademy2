require 'swagger_helper'

RSpec.describe 'API Register — Set PIN', type: :request do
  path '/api/v1/register/set_pin' do
    post 'Submit PIN (first step)' do
      tags 'Register'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :params, in: :body, schema: {
        type: :object,
        properties: {
          flow_id: { type: :string },
          pin: { type: :string }
        },
        required: %i[flow_id pin]
      }

      response '200', 'PIN accepted' do
        let!(:flow) { create(:registration_flow, phone_verified: true) }

        let(:params) do
          { flow_id: flow.id, pin: '1234' }
        end

        schema JSON.parse(File.read(Rails.root.join(
                                      'spec/support/api/schemas/register/set_pin.json'
                                    )))

        run_test! do
          expect(response).to match_json_schema('register/set_pin')
          flow.reload
          expect(flow.pin_temp).to eq('1234')
          expect(flow.step).to eq('confirm_pin')
        end
      end

      response '422', 'Invalid PIN' do
        let!(:flow) { create(:registration_flow, phone_verified: true) }

        let(:params) { { flow_id: flow.id, pin: '12' } }

        run_test! do
          expect(JSON.parse(response.body)['errors']).to be_present
        end
      end
    end
  end
end
