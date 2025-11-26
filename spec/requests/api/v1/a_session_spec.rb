require 'swagger_helper'

RSpec.describe 'Sessions', type: :request do
  describe 'Sessions' do
    path '/api/v1/session' do
      post 'Creates a session' do
        tags 'Session'
        produces 'application/json'
        consumes 'application/json'

        parameter name: :params, in: :body, schema: {
          properties: {
            user: { type: :object,
                    properties: {
                      email: { type: :string },
                      password: { type: :string }
                    } }
          },
          required: %i[email password]
        }

        response '201', 'session create' do
          let!(:user) { create(:user) }
          let(:params) do
            {
              user: {
                email: user.email,
                password: user.password
              }
            }
          end

          schema JSON.parse(
            File.read(Rails.root.join('spec/support/api/schemas/session/create.json'))
          )

          run_test! do
            expect(response).to match_json_schema('session/create')

            # Verify login event was logged
            login_event = Event.where(event_type: 'user_login', user: user).last
            expect(login_event).to be_present
            expect(login_event.data['login_method']).to eq('api')
            expect(login_event.client).to eq('api')
            expect(login_event.school).to eq(user.school)
          end
        end
      end
    end
  end
end
