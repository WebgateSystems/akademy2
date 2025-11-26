require 'swagger_helper'

RSpec.describe 'API Register — Phone Verification', type: :request do
  path '/api/v1/register/verify_phone' do
    post 'Verify phone code' do
      tags 'Register'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :params, in: :body, schema: {
        type: :object,
        properties: {
          flow_id: { type: :string },
          code: { type: :string }
        },
        required: %i[flow_id code]
      }

      response '200', 'Phone verified' do
        let!(:flow) { create(:registration_flow, phone_code: '0000') }

        let(:params) do
          { flow_id: flow.id, code: '0000' }
        end

        schema JSON.parse(File.read(Rails.root.join(
                                      'spec/support/api/schemas/register/verify_phone.json'
                                    )))

        run_test! do
          expect(response).to match_json_schema('register/verify_phone')
        end
      end

      response '422', 'Wrong code' do
        let!(:flow) { create(:registration_flow, phone_code: '0000') }

        let(:params) do
          { flow_id: flow.id, code: '9999' }
        end

        run_test! do
          expect(JSON.parse(response.body)['errors']).to include('Invalid code')
        end
      end
    end
  end
end
