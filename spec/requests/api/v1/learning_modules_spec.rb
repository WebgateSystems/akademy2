# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API V1 LearningModules', type: :request do
  let(:user) { create(:user) }
  let(:token) { Jwt::TokenService.encode({ user_id: user.id }) }
  let(:headers) { { 'Authorization' => "Bearer #{token}" } }

  def success_result(status: :ok, form: { items: [] })
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

  describe 'GET /api/v1/learning_modules' do
    it 'returns 200' do
      allow(Api::V1::LearningModules::ListLearningModules).to receive(:call).and_return(success_result)
      get '/api/v1/learning_modules', headers: headers
      expect(response).to have_http_status(:ok)
    end

    it 'returns 401 without token' do
      get '/api/v1/learning_modules'
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'GET /api/v1/learning_modules/:id' do
    it 'returns 200' do
      allow(Api::V1::LearningModules::ShowLearningModule).to receive(:call).and_return(success_result(form: {}))
      get "/api/v1/learning_modules/#{SecureRandom.uuid}", headers: headers
      expect(response).to have_http_status(:ok)
    end

    it 'returns 404 when not found' do
      result = double(status: :not_found, success?: false, message: 'Not found')
      allow(Api::V1::LearningModules::ShowLearningModule).to receive(:call).and_return(result)
      get "/api/v1/learning_modules/#{SecureRandom.uuid}", headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 401 without token' do
      get "/api/v1/learning_modules/#{SecureRandom.uuid}"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Learning Modules API', type: :request do
  include ApplicationTestHelper

  let(:admin_role) { Role.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' } }
  let(:admin_user) do
    user = create(:user)
    UserRole.find_or_create_by!(user: user, role: admin_role) { |ur| ur.school = user.school }
    user
  end
  let(:auth_token) { "Bearer #{generate_token(admin_user)}" }

  path '/api/v1/learning_modules' do
    get 'List learning modules' do
      tags 'Learning Modules'
      produces 'application/json'
      security [bearerAuth: []]
      description 'Returns only published learning modules'

      response '200', 'learning modules list' do
        before do
          subject1 = create(:subject, title: 'Subject 1', school_id: nil, order_index: 1)
          subject2 = create(:subject, title: 'Subject 2', school_id: nil, order_index: 2)
          unit1 = create(:unit, subject: subject1, title: 'Unit 1', order_index: 1)
          unit2 = create(:unit, subject: subject2, title: 'Unit 2', order_index: 1)
          create(:learning_module, unit: unit1, title: 'Module 1', order_index: 1, published: true)
          create(:learning_module, unit: unit2, title: 'Module 2', order_index: 1, published: true)
          create(:learning_module, unit: unit1, title: 'Module 3', order_index: 2, published: false)
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
                           title: { type: :string },
                           order_index: { type: :integer },
                           unit_id: { type: :string, format: :uuid },
                           published: { type: :boolean },
                           single_flow: { type: :boolean },
                           unit_title: { type: :string },
                           subject_title: { type: :string },
                           subject_id: { type: :string, format: :uuid },
                           contents_count: { type: :integer },
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
          # Should only return published modules
          expect(json['data'].length).to eq(2)
          json['data'].each do |module_data|
            expect(module_data['attributes']['published']).to be true
          end
        end
      end

      response '401', 'unauthorized' do
        let(:Authorization) { nil }

        run_test! do
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end

  path '/api/v1/learning_modules/{id}' do
    parameter name: :id, in: :path, type: :string, format: :uuid

    get 'Show learning module' do
      tags 'Learning Modules'
      produces 'application/json'
      security [bearerAuth: []]
      description 'Returns learning module details. Only published modules are accessible (unless admin)'

      response '200', 'learning module found' do
        let(:subject_record) { create(:subject, title: 'Test Subject', school_id: nil, order_index: 1) }
        let(:unit) { create(:unit, subject: subject_record, title: 'Test Unit', order_index: 1) }
        let(:learning_module) do
          create(:learning_module, unit: unit, title: 'Test Module', order_index: 1, published: true)
        end
        let(:id) { learning_module.id }
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
                         title: { type: :string },
                         order_index: { type: :integer },
                         unit_id: { type: :string, format: :uuid },
                         published: { type: :boolean },
                         single_flow: { type: :boolean },
                         unit_title: { type: :string },
                         subject_title: { type: :string },
                         subject_id: { type: :string, format: :uuid },
                         contents_count: { type: :integer },
                         created_at: { type: :string },
                         updated_at: { type: :string }
                       }
                     }
                   }
                 }
               }

        run_test! do
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['data']['attributes']['title']).to eq('Test Module')
          expect(json['data']['attributes']['published']).to be true
        end
      end

      response '404', 'learning module not found' do
        let(:id) { SecureRandom.uuid }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:not_found)
        end
      end

      response '403', 'forbidden - unpublished module' do
        let(:subject_record) { create(:subject, school_id: nil, order_index: 1) }
        let(:unit) { create(:unit, subject: subject_record, order_index: 1) }
        let(:learning_module) { create(:learning_module, unit: unit, published: false) }
        let(:id) { learning_module.id }
        let(:student_user) do
          user = create(:user)
          student_role = Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' }
          UserRole.create!(user: user, role: student_role, school: user.school)
          user
        end
        let(:Authorization) { "Bearer #{generate_token(student_user)}" }

        run_test! do
          expect(response).to have_http_status(:forbidden)
        end
      end

      response '401', 'unauthorized' do
        let(:subject_record) { create(:subject, school_id: nil) }
        let(:unit) { create(:unit, subject: subject_record) }
        let(:learning_module) { create(:learning_module, unit: unit, published: true) }
        let(:id) { learning_module.id }
        let(:Authorization) { nil }

        run_test! do
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end
end
