require 'swagger_helper'

RSpec.describe 'Schools API', type: :request do
  include ApplicationTestHelper

  let(:admin_role) { Role.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' } }
  let(:admin_user) do
    user = create(:user)
    UserRole.find_or_create_by!(user: user, role: admin_role) { |ur| ur.school = user.school }
    user
  end
  let(:auth_token) { "Bearer #{generate_token(admin_user)}" }

  path '/api/v1/schools' do
    get 'List schools' do
      tags 'Schools'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'schools list' do
        let!(:school1) { create(:school, name: 'School 1', city: 'Gdynia') }
        let!(:school2) { create(:school, name: 'School 2', city: 'Warsaw') }
        let(:Authorization) { auth_token }

        schema type: :object,
               properties: {
                 data: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       id: { type: :string, format: :uuid },
                       type: { type: :string },
                       attributes: {
                         type: :object,
                         properties: {
                           id: { type: :string, format: :uuid },
                           name: { type: :string },
                           slug: { type: :string },
                           address: { type: :string, nullable: true },
                           city: { type: :string },
                           postcode: { type: :string, nullable: true },
                           country: { type: :string },
                           phone: { type: :string, nullable: true },
                           email: { type: :string, nullable: true },
                           homepage: { type: :string, nullable: true },
                           logo_url: { type: :string, nullable: true },
                           created_at: { type: :string },
                           updated_at: { type: :string }
                         }
                       }
                     }
                   }
                 }
               }

        run_test! do
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['data']).to be_an(Array)
          expect(json['data'].length).to be >= 2
        end
      end

      response '401', 'unauthorized' do
        let(:Authorization) { nil }

        run_test! do
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end

    post 'Create school' do
      tags 'Schools'
      produces 'application/json'
      consumes 'multipart/form-data'
      security [bearerAuth: []]

      parameter name: :school, in: :formData, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          slug: { type: :string },
          address: { type: :string },
          city: { type: :string },
          postcode: { type: :string },
          country: { type: :string },
          phone: { type: :string },
          email: { type: :string },
          homepage: { type: :string },
          logo: { type: :string, format: :binary }
        },
        required: %i[name city]
      }

      response '201', 'school created' do
        let(:Authorization) { auth_token }
        let(:school) do
          {
            name: 'New School',
            city: 'Gdynia',
            address: 'Test Street 1',
            postcode: '81-000',
            phone: '+48 123 456 789',
            email: 'school@example.com',
            homepage: 'https://school.example.com'
          }
        end

        schema type: :object,
               properties: {
                 data: {
                   type: :object,
                   properties: {
                     id: { type: :string, format: :uuid },
                     type: { type: :string },
                     attributes: {
                       type: :object,
                       properties: {
                         id: { type: :string, format: :uuid },
                         name: { type: :string },
                         slug: { type: :string },
                         city: { type: :string },
                         country: { type: :string }
                       }
                     }
                   }
                 }
               }

        run_test! do
          expect(response).to have_http_status(:created)
          json = JSON.parse(response.body)
          expect(json['data']['attributes']['name']).to eq('New School')
        end
      end

      response '422', 'invalid request' do
        let(:Authorization) { auth_token }
        let(:school) { { name: '', city: '' } }

        run_test! do
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  path '/api/v1/schools/{id}' do
    parameter name: :id, in: :path, type: :string, format: :uuid

    get 'Show school' do
      tags 'Schools'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'school found' do
        let(:school) { create(:school, name: 'Test School') }
        let(:id) { school.id }
        let(:Authorization) { auth_token }

        schema type: :object,
               properties: {
                 data: {
                   type: :object,
                   properties: {
                     id: { type: :string, format: :uuid },
                     type: { type: :string },
                     attributes: {
                       type: :object,
                       properties: {
                         id: { type: :string, format: :uuid },
                         name: { type: :string },
                         slug: { type: :string },
                         city: { type: :string }
                       }
                     }
                   }
                 }
               }

        run_test! do
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['data']['attributes']['name']).to eq('Test School')
        end
      end

      response '404', 'school not found' do
        let(:id) { SecureRandom.uuid }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    patch 'Update school' do
      tags 'Schools'
      produces 'application/json'
      consumes 'multipart/form-data'
      security [bearerAuth: []]

      parameter name: :school, in: :formData, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          slug: { type: :string },
          address: { type: :string },
          city: { type: :string },
          postcode: { type: :string },
          country: { type: :string },
          phone: { type: :string },
          email: { type: :string },
          homepage: { type: :string },
          logo: { type: :string, format: :binary }
        }
      }

      response '200', 'school updated' do
        let(:school_record) { create(:school, name: 'Old Name') }
        let(:id) { school_record.id }
        let(:Authorization) { auth_token }
        let(:school) { { name: 'Updated Name', city: 'Warsaw' } }

        run_test! do
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['data']['attributes']['name']).to eq('Updated Name')
        end
      end

      response '422', 'invalid request' do
        let(:school_record) { create(:school) }
        let(:id) { school_record.id }
        let(:Authorization) { auth_token }
        let(:school) { { name: '' } }

        run_test! do
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    delete 'Delete school' do
      tags 'Schools'
      security [bearerAuth: []]

      response '204', 'school deleted' do
        let!(:school_record) { create(:school) }
        let(:id) { school_record.id }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:no_content)
          expect(School.find_by(id: id)).to be_nil
        end
      end

      response '404', 'school not found' do
        let(:id) { SecureRandom.uuid }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
