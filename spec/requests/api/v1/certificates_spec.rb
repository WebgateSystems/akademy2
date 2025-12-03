require 'swagger_helper'

RSpec.describe 'Certificates API', type: :request do
  path '/api/v1/certificates/{id}' do
    get 'Fetch certificate info' do
      tags 'Certificates'
      produces 'application/json'
      parameter name: :id, in: :path, type: :string, description: 'Certificate ID'

      response '200', 'certificate found' do
        let!(:certificate) { create(:certificate) }
        let(:id) { certificate.id }

        schema JSON.parse(
          File.read(
            Rails.root.join('spec/support/api/schemas/certificates/show.json')
          )
        )

        run_test! do
          expect(response).to match_json_schema('certificates/show')
        end
      end

      response '404', 'not found' do
        let(:id) { 'non-existing' }

        run_test!
      end
    end
  end

  path '/api/v1/certificates/{id}/download' do
    get 'Download certificate PDF' do
      tags 'Certificates'
      produces 'application/pdf'
      parameter name: :id, in: :path, type: :string

      response '200', 'pdf returned' do
        let!(:certificate) { create(:certificate) }
        let(:id) { certificate.id }

        run_test! do
          expect(response.headers['Content-Type']).to eq('application/pdf')
          expect(response.body).not_to be_empty
        end
      end

      response '404', 'certificate not found' do
        let(:id) { 'invalid-id' }
        run_test!
      end
    end
  end
end
