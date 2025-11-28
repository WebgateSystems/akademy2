require 'swagger_helper'

RSpec.describe 'Events API', type: :request do
  let!(:user) { create(:user) }
  let(:Authorization) { "Bearer #{generate_token(user)}" }
  let(:role) { create(:role, name: 'admin', key: 'admin') }

  before do
    create(:user_role, user:, role:, school: user.school)
  end

  path '/api/v1/events' do
    get 'List all events' do
      tags 'Events'
      produces 'application/json'
      security [Bearer: []]

      parameter name: :Authorization, in: :header, type: :string, required: false

      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false
      parameter name: :from, in: :query, type: :string, required: false
      parameter name: :to, in: :query, type: :string, required: false
      parameter name: :search, in: :query, type: :string, required: false

      response '200', 'events loaded' do
        let!(:event1) do
          create(:event,
                 event_type: 'login',
                 occurred_at: 5.days.ago,
                 data: { ip: '1.1.1.1' },
                 user:)
        end

        let!(:event2) do
          create(:event,
                 event_type: 'update',
                 occurred_at: 2.days.ago,
                 data: { details: 'changed_email' },
                 user:)
        end

        run_test! do
          event1
          event2

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          expect(body['data'].size).to eq(2)
          expect(body['pagination']).to include(
            'page' => 1,
            'per_page' => 20,
            'total' => 2
          )
        end
      end

      response '403', 'no permissions' do
        let(:role) { create(:role) }

        run_test! do
          expect(response).to have_http_status(:forbidden)
          expect(JSON.parse(response.body)['errors']).to eq(['Access Denied'])
        end
      end
    end
  end
end
