require 'swagger_helper'

RSpec.describe 'API Register — Profile Step', type: :request do
  path '/api/v1/register/profile' do
    post 'Submit profile form' do
      tags 'Register'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :params, in: :body, schema: {
        type: :object,
        properties: {
          flow_id: { type: :string, format: :uuid },
          profile: {
            type: :object,
            properties: {
              first_name: { type: :string },
              last_name: { type: :string },
              email: { type: :string },
              birthdate: { type: :string },
              phone: { type: :string }
            },
            required: %i[first_name last_name email birthdate phone]
          }
        },
        required: %i[flow_id profile]
      }

      response '200', 'Profile accepted' do
        let!(:flow) { create(:registration_flow) }

        let(:params) do
          {
            flow_id: flow.id,
            profile: {
              first_name: 'John',
              last_name: 'Doe',
              email: 'john@example.com',
              birthdate: '10.01.2000',
              phone: '+48123456789'
            }
          }
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

        schema JSON.parse(File.read(Rails.root.join(
                                      'spec/support/api/schemas/register/profile.json'
                                    )))

        run_test! do
          expect(response).to match_json_schema('register/profile')
          flow.reload
          expect(flow.step).to eq('verify_phone')
          expect(flow.data['profile']['email']).to eq('john@example.com')
        end
      end

      response '422', 'Invalid profile' do
        let!(:flow) { create(:registration_flow) }

        let(:params) do
          {
            flow_id: flow.id,
            profile: {
              first_name: '',
              last_name: '',
              email: 'broken',
              birthdate: '111',
              phone: '123'
            }
          }
        end

        run_test! do
          expect(JSON.parse(response.body)['errors']).to be_present
        end
      end
    end
  end
end
