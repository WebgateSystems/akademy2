# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API V1 Headmasters', type: :request do
  let(:user) { create(:user) }
  let(:token) { Jwt::TokenService.encode({ user_id: user.id }) }
  let(:headers) { { 'Authorization' => "Bearer #{token}" } }

  def success_result(status: :ok, form: { data: {} })
    double(
      status: status,
      success?: true,
      form: form,
      serializer: nil,
      headers: {},
      pagination: nil,
      access_token: nil,
      to_h: {}
    )
  end

  describe 'GET /api/v1/headmasters' do
    it 'returns 200' do
      allow(Api::V1::Headmasters::ListHeadmasters).to receive(:call).and_return(success_result)
      get '/api/v1/headmasters', headers: headers
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /api/v1/headmasters/:id' do
    it 'returns 200' do
      allow(Api::V1::Headmasters::ShowHeadmaster).to receive(:call).and_return(success_result(form: {}))
      get "/api/v1/headmasters/#{SecureRandom.uuid}", headers: headers
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /api/v1/headmasters' do
    it 'returns 201 on success' do
      result = success_result(status: :created)
      allow(Api::V1::Headmasters::CreateHeadmaster).to receive(:call).and_return(result)
      post '/api/v1/headmasters', headers: headers
      expect(response).to have_http_status(:created)
    end

    it 'returns 422 on validation error' do
      result = double(status: :unprocessable_entity, success?: false, message: ['Invalid'])
      allow(Api::V1::Headmasters::CreateHeadmaster).to receive(:call).and_return(result)
      post '/api/v1/headmasters', headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH /api/v1/headmasters/:id' do
    it 'returns 200 on success' do
      result = success_result(status: :ok)
      allow(Api::V1::Headmasters::UpdateHeadmaster).to receive(:call).and_return(result)
      patch "/api/v1/headmasters/#{SecureRandom.uuid}", headers: headers
      expect(response).to have_http_status(:ok)
    end

    it 'returns 422 on validation error' do
      result = double(status: :unprocessable_entity, success?: false, message: ['Invalid'])
      allow(Api::V1::Headmasters::UpdateHeadmaster).to receive(:call).and_return(result)
      patch "/api/v1/headmasters/#{SecureRandom.uuid}", headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'DELETE /api/v1/headmasters/:id' do
    it 'returns 200 on success' do
      result = success_result(status: :ok)
      allow(Api::V1::Headmasters::DestroyHeadmaster).to receive(:call).and_return(result)
      delete "/api/v1/headmasters/#{SecureRandom.uuid}", headers: headers
      expect(response).to have_http_status(:ok)
    end

    it 'returns 404 when not found' do
      result = double(status: :not_found, success?: false, message: 'Not found')
      allow(Api::V1::Headmasters::DestroyHeadmaster).to receive(:call).and_return(result)
      delete "/api/v1/headmasters/#{SecureRandom.uuid}", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end
end

require 'swagger_helper'

RSpec.describe 'Headmasters API', type: :request do
  include ApplicationTestHelper

  let(:admin_role) { Role.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' } }
  let(:admin_user) do
    user = create(:user)
    UserRole.find_or_create_by!(user: user, role: admin_role) { |ur| ur.school = user.school }
    user
  end
  let(:auth_token) { "Bearer #{generate_token(admin_user)}" }
  let(:principal_role) { Role.find_or_create_by!(key: 'principal') { |r| r.name = 'Principal' } }
  let(:school) { create(:school) }

  path '/api/v1/headmasters' do
    get 'List headmasters' do
      tags 'Headmasters'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'headmasters list' do
        before do
          user1 = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user1, role: principal_role, school: school)
          user2 = create(:user, first_name: 'Anna', last_name: 'Nowak', school: school)
          UserRole.create!(user: user2, role: principal_role, school: school)
        end

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
                           first_name: { type: :string },
                           last_name: { type: :string },
                           name: { type: :string },
                           email: { type: :string },
                           school_id: { type: :string, format: :uuid },
                           school_name: { type: :string, nullable: true },
                           phone: { type: :string, nullable: true },
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

    post 'Create headmaster' do
      tags 'Headmasters'
      produces 'application/json'
      consumes 'application/json'
      security [bearerAuth: []]

      parameter name: :headmaster, in: :body, schema: {
        type: :object,
        properties: {
          headmaster: {
            type: :object,
            properties: {
              first_name: { type: :string },
              last_name: { type: :string },
              email: { type: :string },
              school_id: { type: :string, format: :uuid },
              metadata: {
                type: :object,
                properties: {
                  phone: { type: :string }
                }
              }
            },
            required: %i[first_name last_name email school_id]
          }
        }
      }

      response '201', 'headmaster created' do
        let(:Authorization) { auth_token }
        let(:headmaster) do
          {
            headmaster: {
              first_name: 'Jan',
              last_name: 'Kowalski',
              email: 'jan.kowalski@example.com',
              school_id: school.id,
              metadata: {
                phone: '+48 123 456 789'
              }
            }
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
                         first_name: { type: :string },
                         last_name: { type: :string },
                         name: { type: :string },
                         email: { type: :string },
                         school_id: { type: :string, format: :uuid }
                       }
                     }
                   }
                 }
               }

        run_test! do
          expect(response).to have_http_status(:created)
          json = JSON.parse(response.body)
          expect(json['data']['attributes']['first_name']).to eq('Jan')
          expect(json['data']['attributes']['last_name']).to eq('Kowalski')
        end
      end

      response '422', 'invalid request' do
        let(:Authorization) { auth_token }
        let(:headmaster) { { headmaster: { email: 'invalid-email', school_id: school.id } } }

        run_test! do
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  path '/api/v1/headmasters/{id}' do
    parameter name: :id, in: :path, type: :string, format: :uuid

    get 'Show headmaster' do
      tags 'Headmasters'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'headmaster found' do
        let(:headmaster_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user, role: principal_role, school: school)
          user
        end
        let(:id) { headmaster_record.id }
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
                         first_name: { type: :string },
                         last_name: { type: :string },
                         name: { type: :string },
                         email: { type: :string },
                         school_id: { type: :string, format: :uuid }
                       }
                     }
                   }
                 }
               }

        run_test! do
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['data']['attributes']['first_name']).to eq('Jan')
        end
      end

      response '404', 'headmaster not found' do
        let(:id) { SecureRandom.uuid }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    patch 'Update headmaster' do
      tags 'Headmasters'
      produces 'application/json'
      consumes 'application/json'
      security [bearerAuth: []]

      parameter name: :headmaster, in: :body, schema: {
        type: :object,
        properties: {
          headmaster: {
            type: :object,
            properties: {
              first_name: { type: :string },
              last_name: { type: :string },
              email: { type: :string },
              school_id: { type: :string, format: :uuid },
              metadata: {
                type: :object,
                properties: {
                  phone: { type: :string }
                }
              }
            }
          }
        }
      }

      response '200', 'headmaster updated' do
        let(:headmaster_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user, role: principal_role, school: school)
          user
        end
        let(:id) { headmaster_record.id }
        let(:Authorization) { auth_token }
        let(:headmaster) do
          {
            headmaster: {
              first_name: 'Jan',
              last_name: 'Nowak',
              email: headmaster_record.email,
              school_id: school.id,
              metadata: {
                phone: '+48 999 888 777'
              }
            }
          }
        end

        run_test! do
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['data']['attributes']['last_name']).to eq('Nowak')
        end
      end

      response '422', 'invalid request' do
        let(:headmaster_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user, role: principal_role, school: school)
          user
        end
        let(:id) { headmaster_record.id }
        let(:Authorization) { auth_token }
        let(:headmaster) { { headmaster: { email: 'invalid-email' } } }

        run_test! do
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    delete 'Delete headmaster' do
      tags 'Headmasters'
      security [bearerAuth: []]

      response '204', 'headmaster deleted' do
        let!(:headmaster_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user, role: principal_role, school: school)
          user
        end
        let(:id) { headmaster_record.id }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:no_content)
          expect(User.find_by(id: id)).to be_nil
        end
      end

      response '404', 'headmaster not found' do
        let(:id) { SecureRandom.uuid }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
