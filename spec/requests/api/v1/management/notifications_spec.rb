# frozen_string_literal: true

require 'swagger_helper'

# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe 'Management Notifications API', type: :request do
  include ApplicationTestHelper

  let!(:principal_role) { Role.find_or_create_by!(key: 'principal') { |r| r.name = 'Principal' } }
  let!(:school_manager_role) { Role.find_or_create_by!(key: 'school_manager') { |r| r.name = 'School Manager' } }
  let!(:teacher_role) { Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }

  let(:school) { create(:school) }
  let(:principal) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: principal_role, school: school)
    user
  end
  let(:school_manager) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: school_manager_role, school: school)
    user
  end
  let(:auth_token) { "Bearer #{generate_token(school_manager)}" }

  before do
    # Ensure principal and school_manager exist before creating notifications
    principal
    school_manager
  end

  path '/api/v1/management/notifications/mark_as_read' do
    post 'Mark notification as read' do
      tags 'Management Notifications'
      produces 'application/json'
      consumes 'application/json'
      security [bearerAuth: []]

      parameter name: :notification, in: :body, schema: {
        type: :object,
        properties: {
          notification_id: { type: :string, format: :uuid, description: 'Notification ID' }
        },
        required: [:notification_id]
      }

      response '200', 'notification marked as read' do
        let(:teacher) do
          user = create(:user, school: school, confirmed_at: nil)
          UserRole.create!(user: user, role: teacher_role, school: school)
          user
        end

        let!(:notification_record) do
          NotificationService.create_teacher_awaiting_approval(teacher: teacher, school: school)
          Notification.find_by(
            notification_type: 'teacher_awaiting_approval',
            school: school,
            target_role: 'school_manager'
          )
        end

        let(:Authorization) { auth_token }
        let(:notification) { { notification_id: notification_record.id.to_s } }

        schema type: :object,
               properties: {
                 success: { type: :boolean },
                 message: { type: :string }
               }

        run_test! do
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['success']).to be true
          expect(json['message']).to include('marked as read')

          # Verify notification was marked as read
          notification_record.reload
          expect(notification_record.read_at).to be_present
          expect(notification_record.read_by_user).to eq(school_manager)

          # Verify event was logged
          event = Event.where(event_type: 'notification_read', user: school_manager).last
          expect(event).to be_present
          expect(event.data['notification_type']).to eq('teacher_awaiting_approval')
        end
      end

      response '400', 'bad request when notification_id is missing' do
        let(:Authorization) { auth_token }
        let(:notification) { {} }

        run_test! do
          expect(response).to have_http_status(:bad_request)
          json = JSON.parse(response.body)
          expect(json['error']).to include('required')
        end
      end

      response '404', 'notification not found' do
        let(:Authorization) { auth_token }
        let(:notification) { { notification_id: SecureRandom.uuid } }

        run_test! do
          expect(response).to have_http_status(:not_found)
          json = JSON.parse(response.body)
          expect(json['error']).to include('not found')
        end
      end

      response '401', 'unauthorized' do
        let(:Authorization) { nil }
        let(:notification) { { notification_id: SecureRandom.uuid } }

        run_test! do
          expect(response).to have_http_status(:unauthorized)
        end
      end

      response '403', 'forbidden for non-school-management users' do
        let(:admin_role) { Role.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' } }
        let(:admin_user) do
          user = create(:user, school: school)
          UserRole.create!(user: user, role: admin_role, school: school)
          user
        end
        let(:Authorization) { "Bearer #{generate_token(admin_user)}" }
        let(:notification) { { notification_id: SecureRandom.uuid } }

        run_test! do
          expect(response).to have_http_status(:forbidden)
          json = JSON.parse(response.body)
          expect(json['error']).to include('uprawnień')
        end
      end
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
