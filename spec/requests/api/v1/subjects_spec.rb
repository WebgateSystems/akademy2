require 'swagger_helper'

RSpec.describe 'Api::V1::Subjects', type: :request do
  let!(:user) { create(:user) }
  let(:Authorization) { "Bearer #{generate_token(user)}" }

  path '/api/v1/subjects' do
    get 'List subjects' do
      tags 'Subjects'
      produces 'application/json'

      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :page, in: :query, type: :integer, required: false

      let!(:subjects) { create_list(:subject, 5, school: user.school) }

      response '200', 'subjects listed' do
        schema JSON.parse(
          File.read(Rails.root.join('spec/support/api/schemas/subjects/index.json'))
        )

        run_test! do
          expect(response).to match_json_schema('subjects/index')
          expect(response).to have_http_status(:ok)

          json = JSON.parse(response.body)

          expect(json['data']).to be_an(Array)
          expect(json['data'].size).to eq(5)

          expect(json['data'].map { |s| s['id'] }).to match_array(subjects.map(&:id))

          expect(json['pagination']).to include(
            'page' => 1,
            'total' => 1
          )
        end
      end
    end
  end
end
