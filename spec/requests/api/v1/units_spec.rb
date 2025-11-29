# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Units API', type: :request do
  include ApplicationTestHelper

  let(:admin_role) { Role.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' } }
  let(:admin_user) do
    user = create(:user)
    UserRole.find_or_create_by!(user: user, role: admin_role) { |ur| ur.school = user.school }
    user
  end
  let(:auth_token) { "Bearer #{generate_token(admin_user)}" }

  path '/api/v1/units' do
    get 'List units' do
      tags 'Units'
      produces 'application/json'
      security [bearerAuth: []]

      parameter name: :subject_id, in: :query, type: :string, format: :uuid, required: false,
                description: 'Filter by subject ID'

      response '200', 'units list' do
        before do
          subject1 = create(:subject, title: 'Subject 1', school_id: nil, order_index: 1)
          subject2 = create(:subject, title: 'Subject 2', school_id: nil, order_index: 2)
          create(:unit, subject: subject1, title: 'Unit 1', order_index: 1)
          create(:unit, subject: subject2, title: 'Unit 2', order_index: 1)
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
                           subject_id: { type: :string, format: :uuid },
                           subject_title: { type: :string },
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

      response '200', 'units filtered by subject_id' do
        before do
          subject1 = create(:subject, title: 'Subject 1', school_id: nil, order_index: 1)
          subject2 = create(:subject, title: 'Subject 2', school_id: nil, order_index: 2)
          create(:unit, subject: subject1, title: 'Unit 1', order_index: 1)
          create(:unit, subject: subject2, title: 'Unit 2', order_index: 1)
        end

        let(:subject_record) { Subject.first }
        let(:subject_id) { subject_record.id }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['data']).to be_an(Array)
          json['data'].each do |unit|
            expect(unit['attributes']['subject_id']).to eq(subject_record.id.to_s)
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

  path '/api/v1/units/{id}' do
    parameter name: :id, in: :path, type: :string, format: :uuid

    get 'Show unit' do
      tags 'Units'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'unit found' do
        let(:subject_record) { create(:subject, title: 'Test Subject', school_id: nil, order_index: 1) }
        let(:unit) { create(:unit, subject: subject_record, title: 'Test Unit', order_index: 1) }
        let(:id) { unit.id }
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
                         subject_id: { type: :string, format: :uuid },
                         subject_title: { type: :string },
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
          expect(json['data']['attributes']['title']).to eq('Test Unit')
          expect(json['data']['attributes']['subject_title']).to eq('Test Subject')
        end
      end

      response '404', 'unit not found' do
        let(:id) { SecureRandom.uuid }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:not_found)
        end
      end

      response '401', 'unauthorized' do
        let(:subject_record) { create(:subject, school_id: nil) }
        let(:unit) { create(:unit, subject: subject_record) }
        let(:id) { unit.id }
        let(:Authorization) { nil }

        run_test! do
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end
end
