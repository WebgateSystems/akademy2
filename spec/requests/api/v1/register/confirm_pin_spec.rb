require 'swagger_helper'

RSpec.describe 'API Register — Confirm PIN', type: :request do
  path '/api/v1/register/confirm_pin' do
    post 'Confirm PIN and complete registration' do
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

      response '201', 'Registration completed' do
        let!(:flow) do
          create(:registration_flow,
                 pin_temp: '1234',
                 step: 'confirm_pin',
                 data: {
                   'profile' => {
                     'first_name' => 'John',
                     'last_name' => 'Doe',
                     'email' => 'john@example.com',
                     'birthdate' => '10.01.2000',
                     'phone' => '+48123456789'
                   }
                 })
        end

        let(:params) { { flow_id: flow.id, pin: '1234' } }

        schema JSON.parse(File.read(Rails.root.join(
                                      'spec/support/api/schemas/register/confirm_pin.json'
                                    )))

        run_test! do
          expect(response).to match_json_schema('register/confirm_pin')
          expect(User.find_by(email: 'john@example.com')).to be_present
        end
      end

      response '422', 'PIN mismatch' do
        let!(:flow) { create(:registration_flow, pin_temp: '1234') }

        let(:params) { { flow_id: flow.id, pin: '1111' } }

        run_test! do
          expect(JSON.parse(response.body)['errors']).to include('Codes do not match')
        end
      end
    end
  end
end
