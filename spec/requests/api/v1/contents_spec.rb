# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Contents API', type: :request do
  include ApplicationTestHelper

  let(:admin_role) { Role.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' } }
  let(:admin_user) do
    user = create(:user)
    UserRole.find_or_create_by!(user: user, role: admin_role) { |ur| ur.school = user.school }
    user
  end
  let(:auth_token) { "Bearer #{generate_token(admin_user)}" }

  path '/api/v1/contents' do
    get 'List contents' do
      tags 'Contents'
      produces 'application/json'
      security [bearerAuth: []]

      parameter name: :learning_module_id, in: :query, type: :string, format: :uuid, required: false,
                description: 'Filter by learning module ID'

      response '200', 'contents list' do
        before do
          subject1 = create(:subject, title: 'Subject 1', school_id: nil, order_index: 1)
          unit1 = create(:unit, subject: subject1, title: 'Unit 1', order_index: 1)
          learning_module1 = create(:learning_module, unit: unit1, title: 'Module 1', order_index: 1, published: true)
          learning_module2 = create(:learning_module, unit: unit1, title: 'Module 2', order_index: 2, published: true)
          create(:content, learning_module: learning_module1, title: 'Content 1', content_type: 'video', order_index: 1)
          create(:content, learning_module: learning_module1, title: 'Content 2', content_type: 'quiz', order_index: 2)
          create(:content, learning_module: learning_module2, title: 'Content 3', content_type: 'infographic',
                           order_index: 1)
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
                           content_type: { type: :string },
                           order_index: { type: :integer },
                           learning_module_id: { type: :string, format: :uuid },
                           learning_module_title: { type: :string },
                           duration_sec: { type: :integer, nullable: true },
                           youtube_url: { type: :string, nullable: true },
                           payload: { type: :object, nullable: true },
                           file_url: { type: :string, nullable: true },
                           poster_url: { type: :string, nullable: true },
                           subtitles_url: { type: :string, nullable: true },
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
          expect(json['data'].length).to be >= 3
        end
      end

      response '200', 'contents filtered by learning_module_id' do
        before do
          subject1 = create(:subject, title: 'Subject 1', school_id: nil, order_index: 1)
          unit1 = create(:unit, subject: subject1, title: 'Unit 1', order_index: 1)
          learning_module1 = create(:learning_module, unit: unit1, title: 'Module 1', order_index: 1, published: true)
          learning_module2 = create(:learning_module, unit: unit1, title: 'Module 2', order_index: 2, published: true)
          create(:content, learning_module: learning_module1, title: 'Content 1', content_type: 'video', order_index: 1)
          create(:content, learning_module: learning_module1, title: 'Content 2', content_type: 'quiz', order_index: 2)
          create(:content, learning_module: learning_module2, title: 'Content 3', content_type: 'infographic',
                           order_index: 1)
        end

        let(:learning_module) { LearningModule.first }
        let(:learning_module_id) { learning_module.id }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['data']).to be_an(Array)
          json['data'].each do |content|
            expect(content['attributes']['learning_module_id']).to eq(learning_module.id.to_s)
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

  path '/api/v1/contents/{id}' do
    parameter name: :id, in: :path, type: :string, format: :uuid

    get 'Show content' do
      tags 'Contents'
      produces 'application/json'
      security [bearerAuth: []]
      description 'Returns content details. Only contents from published learning modules are accessible (unless admin)'

      response '200', 'content found' do
        let(:subject_record) { create(:subject, title: 'Test Subject', school_id: nil, order_index: 1) }
        let(:unit) { create(:unit, subject: subject_record, title: 'Test Unit', order_index: 1) }
        let(:learning_module) do
          create(:learning_module, unit: unit, title: 'Test Module', order_index: 1, published: true)
        end
        let(:content) do
          create(:content,
                 learning_module: learning_module,
                 title: 'Test Content',
                 content_type: 'video',
                 order_index: 1,
                 youtube_url: 'https://youtube.com/watch?v=test',
                 duration_sec: 300)
        end
        let(:id) { content.id }
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
                         content_type: { type: :string },
                         order_index: { type: :integer },
                         learning_module_id: { type: :string, format: :uuid },
                         learning_module_title: { type: :string },
                         duration_sec: { type: :integer, nullable: true },
                         youtube_url: { type: :string, nullable: true },
                         payload: { type: :object, nullable: true },
                         file_url: { type: :string, nullable: true },
                         poster_url: { type: :string, nullable: true },
                         subtitles_url: { type: :string, nullable: true },
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
          expect(json['data']['attributes']['title']).to eq('Test Content')
          expect(json['data']['attributes']['content_type']).to eq('video')
          expect(json['data']['attributes']['youtube_url']).to eq('https://youtube.com/watch?v=test')
        end
      end

      response '404', 'content not found' do
        let(:id) { SecureRandom.uuid }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:not_found)
        end
      end

      response '403', 'forbidden - content from unpublished module' do
        let(:subject_record) { create(:subject, school_id: nil, order_index: 1) }
        let(:unit) { create(:unit, subject: subject_record, order_index: 1) }
        let(:learning_module) { create(:learning_module, unit: unit, published: false) }
        let(:content) { create(:content, learning_module: learning_module, content_type: 'video') }
        let(:id) { content.id }
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
        let(:content) { create(:content, learning_module: learning_module, content_type: 'video') }
        let(:id) { content.id }
        let(:Authorization) { nil }

        run_test! do
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end
end
