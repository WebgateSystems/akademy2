# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Subjects API', type: :request do
  include ApplicationTestHelper

  let(:admin_role) { Role.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' } }
  let(:admin_user) do
    user = create(:user)
    UserRole.find_or_create_by!(user: user, role: admin_role) { |ur| ur.school = user.school }
    user
  end
  let(:auth_token) { "Bearer #{generate_token(admin_user)}" }

  path '/api/v1/subjects' do
    get 'List subjects' do
      tags 'Subjects'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'subjects list' do
        before do
          create(:subject, title: 'Subject 1', slug: 'subject-1', school_id: nil, order_index: 1)
          create(:subject, title: 'Subject 2', slug: 'subject-2', school_id: nil, order_index: 2)
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
                           slug: { type: :string },
                           order_index: { type: :integer },
                           icon_url: { type: :string, nullable: true },
                           color_light: { type: :string, nullable: true },
                           color_dark: { type: :string, nullable: true },
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
  end

  path '/api/v1/subjects/with_contents' do
    get 'List subjects with contents' do
      tags 'Subjects'
      produces 'application/json'
      security [bearerAuth: []]
      description 'Returns all subjects with full structure (unit → learning_module → contents) for offline mode'

      response '200', 'subjects with contents' do
        before do
          subject1 = create(:subject, title: 'Subject 1', slug: 'subject-1', school_id: nil, order_index: 1)
          unit1 = create(:unit, subject: subject1, title: 'Unit 1', order_index: 1)
          learning_module1 = create(:learning_module, unit: unit1, title: 'Module 1', order_index: 1, published: true)
          create(:content, learning_module: learning_module1, title: 'Content 1', content_type: 'video', order_index: 1)
          create(:content, learning_module: learning_module1, title: 'Content 2', content_type: 'quiz', order_index: 2)
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
                           slug: { type: :string },
                           order_index: { type: :integer },
                           icon_url: { type: :string, nullable: true },
                           color_light: { type: :string, nullable: true },
                           color_dark: { type: :string, nullable: true },
                           unit: {
                             type: :object,
                             nullable: true,
                             properties: {
                               id: { type: :string, format: :uuid },
                               title: { type: :string },
                               order_index: { type: :integer },
                               learning_module: {
                                 type: :object,
                                 nullable: true,
                                 properties: {
                                   id: { type: :string, format: :uuid },
                                   title: { type: :string },
                                   order_index: { type: :integer },
                                   published: { type: :boolean },
                                   single_flow: { type: :boolean },
                                   contents: {
                                     type: :array,
                                     items: {
                                       type: :object,
                                       properties: {
                                         id: { type: :string, format: :uuid },
                                         title: { type: :string },
                                         content_type: { type: :string },
                                         order_index: { type: :integer },
                                         duration_sec: { type: :integer, nullable: true },
                                         youtube_url: { type: :string, nullable: true },
                                         payload: { type: :object, nullable: true },
                                         file_url: { type: :string, nullable: true },
                                         poster_url: { type: :string, nullable: true },
                                         subtitles_url: { type: :string, nullable: true }
                                       }
                                     }
                                   }
                                 }
                               }
                             }
                           }
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
          expect(json['data'].first['attributes']['unit']).to be_present
          expect(json['data'].first['attributes']['unit']['learning_module']).to be_present
          expect(json['data'].first['attributes']['unit']['learning_module']['contents']).to be_an(Array)
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

  path '/api/v1/subjects/{id}' do
    parameter name: :id, in: :path, type: :string, format: :uuid

    get 'Show subject' do
      tags 'Subjects'
      produces 'application/json'
      security [bearerAuth: []]
      description 'Returns subject details with full structure (unit → learning_module → contents)'

      response '200', 'subject found' do
        before do
          subject_record = create(:subject, title: 'Test Subject', slug: 'test-subject', school_id: nil, order_index: 1)
          unit = create(:unit, subject: subject_record, title: 'Test Unit', order_index: 1)
          learning_module = create(:learning_module, unit: unit, title: 'Test Module', order_index: 1, published: true)
          create(:content, learning_module: learning_module, title: 'Test Content', content_type: 'video',
                           order_index: 1)
        end

        let(:subject_record) { Subject.find_by(title: 'Test Subject') }
        let(:id) { subject_record.id }
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
                         slug: { type: :string },
                         order_index: { type: :integer },
                         icon_url: { type: :string, nullable: true },
                         color_light: { type: :string, nullable: true },
                         color_dark: { type: :string, nullable: true },
                         unit: {
                           type: :object,
                           nullable: true,
                           properties: {
                             id: { type: :string, format: :uuid },
                             title: { type: :string },
                             order_index: { type: :integer },
                             learning_module: {
                               type: :object,
                               nullable: true,
                               properties: {
                                 id: { type: :string, format: :uuid },
                                 title: { type: :string },
                                 order_index: { type: :integer },
                                 published: { type: :boolean },
                                 single_flow: { type: :boolean },
                                 contents: {
                                   type: :array,
                                   items: {
                                     type: :object,
                                     properties: {
                                       id: { type: :string, format: :uuid },
                                       title: { type: :string },
                                       content_type: { type: :string },
                                       order_index: { type: :integer },
                                       duration_sec: { type: :integer, nullable: true },
                                       youtube_url: { type: :string, nullable: true },
                                       payload: { type: :object, nullable: true },
                                       file_url: { type: :string, nullable: true },
                                       poster_url: { type: :string, nullable: true },
                                       subtitles_url: { type: :string, nullable: true }
                                     }
                                   }
                                 }
                               }
                             }
                           }
                         }
                       }
                     }
                   }
                 }
               }

        run_test! do
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['data']['attributes']['title']).to eq('Test Subject')
          expect(json['data']['attributes']['unit']).to be_present
          expect(json['data']['attributes']['unit']['learning_module']).to be_present
          expect(json['data']['attributes']['unit']['learning_module']['contents']).to be_an(Array)
        end
      end

      response '404', 'subject not found' do
        let(:id) { SecureRandom.uuid }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:not_found)
        end
      end

      response '401', 'unauthorized' do
        let(:subject_record) { create(:subject, school_id: nil) }
        let(:id) { subject_record.id }
        let(:Authorization) { nil }

        run_test! do
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end
end
