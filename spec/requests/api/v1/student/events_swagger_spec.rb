# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Student Events API', type: :request do
  let!(:student_role) { Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' } }
  let(:school) { create(:school) }
  let(:student) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: student_role, school: school)
    user
  end
  let(:token) { Jwt::TokenService.encode({ user_id: student.id }, 1.hour.from_now) }
  let(:Authorization) { "Bearer #{token}" }

  let(:school_class) do
    SchoolClass.create!(
      school: school,
      name: '4A',
      year: school.current_academic_year_value,
      qr_token: SecureRandom.uuid,
      metadata: {}
    )
  end

  before do
    StudentClassEnrollment.create!(student: student, school_class: school_class, status: 'approved')
  end

  path '/api/v1/student/events' do
    post 'Log student activity event' do
      tags 'Student'
      description 'Log student activity events (video watched, quiz started, etc.)'
      produces 'application/json'
      consumes 'application/json'
      security [bearerAuth: []]

      parameter name: :params, in: :body, schema: {
        type: :object,
        properties: {
          event_type: {
            type: :string,
            enum: %w[video_started video_completed video_progress infographic_viewed quiz_started content_viewed],
            description: 'Type of event'
          },
          content_id: { type: :string, format: :uuid, description: 'Content ID (for video/infographic)' },
          learning_module_id: { type: :string, format: :uuid, description: 'Learning module ID' },
          duration_sec: { type: :integer, description: 'Video duration in seconds' },
          progress_sec: { type: :integer, description: 'Current progress in seconds' },
          progress_percent: { type: :integer, description: 'Progress percentage (0-100)' },
          client: { type: :string, enum: %w[web mobile], default: 'web' }
        },
        required: ['event_type']
      }

      response '201', 'event logged' do
        let(:params) do
          {
            event_type: 'video_started',
            content_id: SecureRandom.uuid,
            learning_module_id: SecureRandom.uuid
          }
        end

        schema type: :object,
               properties: {
                 success: { type: :boolean },
                 message: { type: :string }
               }

        run_test! do
          json = JSON.parse(response.body)
          expect(json['success']).to be true
        end
      end

      response '401', 'unauthorized' do
        let(:Authorization) { nil }
        let(:params) { { event_type: 'video_started' } }
        run_test!
      end

      response '422', 'invalid event type' do
        let(:params) { { event_type: 'invalid_type' } }

        schema type: :object,
               properties: {
                 success: { type: :boolean },
                 error: { type: :string }
               }

        run_test! do
          json = JSON.parse(response.body)
          expect(json['error']).to include('Invalid event type')
        end
      end
    end
  end

  path '/api/v1/student/events/batch' do
    post 'Log multiple events (offline sync)' do
      tags 'Student'
      description 'Log multiple events at once for mobile app offline sync'
      produces 'application/json'
      consumes 'application/json'
      security [bearerAuth: []]

      parameter name: :params, in: :body, schema: {
        type: :object,
        properties: {
          events: {
            type: :array,
            items: {
              type: :object,
              properties: {
                event_type: {
                  type: :string,
                  enum: %w[video_started video_completed video_progress infographic_viewed quiz_started content_viewed]
                },
                data: { type: :object, description: 'Event-specific data' },
                client: { type: :string, enum: %w[web mobile] },
                occurred_at: { type: :string, format: :'date-time', description: 'When event occurred (for offline)' }
              },
              required: ['event_type']
            }
          }
        },
        required: ['events']
      }

      response '201', 'all events logged' do
        let(:params) do
          {
            events: [
              { event_type: 'video_started', data: { content_id: SecureRandom.uuid } },
              { event_type: 'video_completed', data: { content_id: SecureRandom.uuid } }
            ]
          }
        end

        schema type: :object,
               properties: {
                 success: { type: :boolean },
                 logged_count: { type: :integer },
                 total_count: { type: :integer }
               }

        run_test! do
          json = JSON.parse(response.body)
          expect(json['logged_count']).to eq(2)
        end
      end

      response '207', 'partial success' do
        let(:params) do
          {
            events: [
              { event_type: 'video_started', data: {} },
              { event_type: 'invalid_type', data: {} }
            ]
          }
        end

        schema type: :object,
               properties: {
                 success: { type: :boolean },
                 logged_count: { type: :integer },
                 total_count: { type: :integer },
                 errors: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       index: { type: :integer },
                       error: { type: :string }
                     }
                   }
                 }
               }

        run_test! do
          json = JSON.parse(response.body)
          expect(json['logged_count']).to eq(1)
          expect(json['errors']).not_to be_empty
        end
      end

      response '401', 'unauthorized' do
        let(:Authorization) { nil }
        let(:params) { { events: [] } }
        run_test!
      end

      response '422', 'events must be an array' do
        let(:params) { { events: 'not an array' } }
        run_test!
      end
    end
  end
end
