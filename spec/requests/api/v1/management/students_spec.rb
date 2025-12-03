# frozen_string_literal: true

require 'swagger_helper'

# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe 'Management Students API', type: :request do
  include ApplicationTestHelper

  let!(:principal_role) { Role.find_or_create_by!(key: 'principal') { |r| r.name = 'Principal' } }
  let!(:school_manager_role) { Role.find_or_create_by!(key: 'school_manager') { |r| r.name = 'School Manager' } }
  let!(:student_role) { Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' } }

  let(:school) { create(:school) }
  let(:school_class) do
    SchoolClass.create!(
      school: school,
      name: '4A',
      year: '2025/2026',
      qr_token: SecureRandom.uuid,
      metadata: {}
    )
  end
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

  path '/api/v1/management/students' do
    get 'List students' do
      tags 'Management Students'
      produces 'application/json'
      security [bearerAuth: []]

      parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number'
      parameter name: :per_page, in: :query, type: :integer, required: false, description: 'Items per page'
      parameter name: :search, in: :query, type: :string, required: false, description: 'Search term'

      response '200', 'students list' do
        let(:student1) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user, role: student_role, school: school)
          StudentClassEnrollment.create!(student: user, school_class: school_class)
          user
        end
        let(:student2) do
          user = create(:user, first_name: 'Anna', last_name: 'Nowak', school: school)
          UserRole.create!(user: user, role: student_role, school: school)
          StudentClassEnrollment.create!(student: user, school_class: school_class)
          user
        end
        let(:Authorization) { auth_token }

        before do
          principal
          school_manager
          school_class
          student1
          student2
        end

        schema type: :object,
               properties: {
                 success: { type: :boolean },
                 data: {
                   type: :object,
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
                               birth_date: { type: :string, nullable: true },
                               class_name: { type: :string, nullable: true },
                               locked_at: { type: :string, nullable: true },
                               is_locked: { type: :boolean },
                               is_confirmed: { type: :boolean },
                               confirmed_at: { type: :string, nullable: true },
                               created_at: { type: :string },
                               updated_at: { type: :string }
                             }
                           }
                         }
                       }
                     },
                     pagination: {
                       type: :object,
                       nullable: true,
                       properties: {
                         page: { type: :integer },
                         per_page: { type: :integer },
                         total: { type: :integer },
                         total_pages: { type: :integer },
                         has_more: { type: :boolean }
                       }
                     }
                   }
                 }
               }

        run_test! do
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['success']).to be true
          expect(json['data']['data']).to be_an(Array)
          expect(json['data']['data'].length).to be >= 2
          expect(json['data']['pagination']).to be_present
        end
      end

      response '401', 'unauthorized' do
        let(:Authorization) { nil }

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

        run_test! do
          expect(response).to have_http_status(:forbidden)
          json = JSON.parse(response.body)
          expect(json['error']).to include('uprawnień')
        end
      end
    end

    post 'Create student' do
      tags 'Management Students'
      produces 'application/json'
      consumes 'application/json'
      security [bearerAuth: []]

      parameter name: :student, in: :body, schema: {
        type: :object,
        properties: {
          student: {
            type: :object,
            properties: {
              first_name: { type: :string },
              last_name: { type: :string },
              email: { type: :string },
              school_class_id: { type: :string, format: :uuid },
              metadata: {
                type: :object,
                properties: {
                  phone: { type: :string },
                  birth_date: { type: :string }
                }
              }
            },
            required: %i[first_name last_name email]
          }
        }
      }

      response '201', 'student created' do
        let(:Authorization) { auth_token }
        let(:student) do
          {
            student: {
              first_name: 'Jan',
              last_name: 'Kowalski',
              email: 'jan.kowalski@example.com',
              school_class_id: school_class.id,
              metadata: {
                phone: '+48 123 456 789',
                birth_date: '15.03.2010'
              }
            }
          }
        end

        schema type: :object,
               properties: {
                 success: { type: :boolean },
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
                         school_id: { type: :string, format: :uuid },
                         class_name: { type: :string, nullable: true }
                       }
                     }
                   }
                 }
               }

        run_test! do
          expect(response).to have_http_status(:created)
          json = JSON.parse(response.body)
          expect(json['success']).to be true
          expect(json['data']['data']['attributes']['first_name']).to eq('Jan')
          expect(json['data']['data']['attributes']['last_name']).to eq('Kowalski')

          # Verify student role was assigned
          created_user = User.find(json['data']['data']['id'])
          expect(created_user.school_id).to eq(school.id)
          expect(created_user.roles.pluck(:key)).to include('student')

          # Verify class enrollment was created
          enrollment = StudentClassEnrollment.find_by(student: created_user, school_class: school_class)
          expect(enrollment).to be_present

          # Verify notification was created
          notification = Notification.find_by(
            notification_type: 'student_awaiting_approval',
            school: school,
            target_role: 'school_manager'
          )
          expect(notification).to be_present
        end
      end

      response '422', 'invalid request' do
        let(:Authorization) { auth_token }
        let(:student) { { student: { email: 'invalid-email' } } }

        run_test! do
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  path '/api/v1/management/students/{id}' do
    parameter name: :id, in: :path, type: :string, format: :uuid

    get 'Show student' do
      tags 'Management Students'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'student found' do
        let(:student_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user, role: student_role, school: school)
          StudentClassEnrollment.create!(student: user, school_class: school_class)
          user
        end
        let(:id) { student_record.id }
        let(:Authorization) { auth_token }

        schema type: :object,
               properties: {
                 success: { type: :boolean },
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
                         school_id: { type: :string, format: :uuid },
                         class_name: { type: :string, nullable: true }
                       }
                     }
                   }
                 }
               }

        run_test! do
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['success']).to be true
          expect(json['data']['data']['attributes']['first_name']).to eq('Jan')
        end
      end

      response '404', 'student not found' do
        let(:id) { SecureRandom.uuid }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    patch 'Update student' do
      tags 'Management Students'
      produces 'application/json'
      consumes 'application/json'
      security [bearerAuth: []]

      parameter name: :student, in: :body, schema: {
        type: :object,
        properties: {
          student: {
            type: :object,
            properties: {
              first_name: { type: :string },
              last_name: { type: :string },
              email: { type: :string },
              school_class_id: { type: :string, format: :uuid },
              metadata: {
                type: :object,
                properties: {
                  phone: { type: :string },
                  birth_date: { type: :string }
                }
              }
            }
          }
        }
      }

      response '200', 'student updated' do
        let(:student_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user, role: student_role, school: school)
          StudentClassEnrollment.create!(student: user, school_class: school_class)
          user
        end
        let(:id) { student_record.id }
        let(:Authorization) { auth_token }
        let(:student) do
          {
            student: {
              first_name: 'Jan Updated',
              last_name: 'Kowalski Updated',
              metadata: {
                phone: '+48 999 888 777'
              }
            }
          }
        end

        run_test! do
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['success']).to be true
          expect(json['data']['data']['attributes']['first_name']).to eq('Jan Updated')
        end
      end
    end

    delete 'Delete student' do
      tags 'Management Students'
      produces 'application/json'
      security [bearerAuth: []]

      response '204', 'student deleted' do
        let(:student_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user, role: student_role, school: school)
          StudentClassEnrollment.create!(student: user, school_class: school_class)
          user
        end
        let(:id) { student_record.id }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:no_content)
          # Student user account is kept, only enrollment is removed
          expect(User.find_by(id: student_record.id)).to be_present
          expect(StudentClassEnrollment.where(student_id: student_record.id)).to be_empty
        end
      end
    end
  end

  path '/api/v1/management/students/{id}/approve' do
    parameter name: :id, in: :path, type: :string, format: :uuid

    post 'Approve student' do
      tags 'Management Students'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'student approved' do
        let(:student_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school, confirmed_at: nil)
          UserRole.create!(user: user, role: student_role, school: school)
          StudentClassEnrollment.create!(student: user, school_class: school_class)
          user
        end
        let(:id) { student_record.id }
        let(:Authorization) { auth_token }

        before do
          principal
          school_manager
          school_class
          # Create notification after managers exist
          NotificationService.create_student_awaiting_approval(student: student_record, school: school)
        end

        schema type: :object,
               properties: {
                 success: { type: :boolean },
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
                         is_confirmed: { type: :boolean }
                       }
                     }
                   }
                 }
               }

        run_test! do
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['success']).to be true

          student_record.reload
          expect(student_record.confirmed_at).to be_present

          # Verify notification was resolved (check all notifications for this student)
          notifications = Notification.where(
            notification_type: 'student_awaiting_approval',
            school: school
          ).where("metadata->>'student_id' = ?", student_record.id.to_s)
          expect(notifications.count).to be > 0
          notifications.each do |notification|
            expect(notification.resolved_at).to be_present
          end

          # Verify event was logged
          event = Event.where(event_type: 'student_approved', user: school_manager).last
          expect(event).to be_present
        end
      end

      response '404', 'student not found' do
        let(:id) { SecureRandom.uuid }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  path '/api/v1/management/students/{id}/decline' do
    parameter name: :id, in: :path, type: :string, format: :uuid

    delete 'Decline student' do
      tags 'Management Students'
      produces 'application/json'
      security [bearerAuth: []]

      response '204', 'student declined and deleted' do
        let(:student_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school, confirmed_at: nil)
          UserRole.create!(user: user, role: student_role, school: school)
          StudentClassEnrollment.create!(student: user, school_class: school_class)
          user
        end
        let(:id) { student_record.id }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:no_content)
          # Student user account is kept, only enrollment is removed
          expect(User.find_by(id: student_record.id)).to be_present
          expect(StudentClassEnrollment.where(student_id: student_record.id)).to be_empty
        end
      end
    end
  end

  path '/api/v1/management/students/{id}/resend_invite' do
    parameter name: :id, in: :path, type: :string, format: :uuid

    post 'Resend invite to student' do
      tags 'Management Students'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'invite resent' do
        let(:student_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user, role: student_role, school: school)
          StudentClassEnrollment.create!(student: user, school_class: school_class)
          user
        end
        let(:id) { student_record.id }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['success']).to be true
        end
      end
    end
  end

  path '/api/v1/management/students/{id}/lock' do
    parameter name: :id, in: :path, type: :string, format: :uuid

    post 'Lock or unlock student account' do
      tags 'Management Students'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'student account locked' do
        let(:student_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user, role: student_role, school: school)
          StudentClassEnrollment.create!(student: user, school_class: school_class)
          user
        end
        let(:id) { student_record.id }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['success']).to be true

          student_record.reload
          expect(student_record.locked_at).to be_present
        end
      end

      response '200', 'student account unlocked' do
        let(:student_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school, locked_at: Time.current)
          UserRole.create!(user: user, role: student_role, school: school)
          StudentClassEnrollment.create!(student: user, school_class: school_class)
          user
        end
        let(:id) { student_record.id }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['success']).to be true

          student_record.reload
          expect(student_record.locked_at).to be_nil
        end
      end
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
