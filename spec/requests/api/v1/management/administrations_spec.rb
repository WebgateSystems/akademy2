# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API V1 Management Administrations', type: :request do
  let(:manager_role) { Role.find_or_create_by!(key: 'school_manager') { |r| r.name = 'School Manager' } }
  let(:school) { create(:school) }
  let(:manager) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: manager_role, school: school)
    user
  end
  let(:token) { Jwt::TokenService.encode({ user_id: manager.id }) }
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

  describe 'GET /api/v1/management/administrations' do
    it 'returns 200' do
      allow(Api::V1::Management::ListAdministrations).to receive(:call).and_return(success_result)
      get '/api/v1/management/administrations', headers: headers
      expect(response).to have_http_status(:ok)
    end

    it 'returns 401 without token' do
      get '/api/v1/management/administrations'
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 403 when forbidden' do
      result = double(status: :forbidden, success?: false, message: ['forbidden'])
      allow(Api::V1::Management::ListAdministrations).to receive(:call).and_return(result)
      get '/api/v1/management/administrations', headers: headers
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST /api/v1/management/administrations' do
    it 'returns 201 on success' do
      result = success_result(status: :created)
      allow(Api::V1::Management::CreateAdministration).to receive(:call).and_return(result)

      post '/api/v1/management/administrations', headers: headers
      expect(response).to have_http_status(:created)
    end
  end
end
# frozen_string_literal: true

require 'swagger_helper'

# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe 'Management Administrations API', type: :request do
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

  path '/api/v1/management/administrations' do
    get 'List administrations' do
      tags 'Management Administrations'
      produces 'application/json'
      security [bearerAuth: []]

      parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number'
      parameter name: :per_page, in: :query, type: :integer, required: false, description: 'Items per page'
      parameter name: :search, in: :query, type: :string, required: false, description: 'Search term'

      response '200', 'administrations list' do
        let(:admin1) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user, role: principal_role, school: school)
          user
        end
        let(:admin2) do
          user = create(:user, first_name: 'Anna', last_name: 'Nowak', school: school)
          UserRole.create!(user: user, role: school_manager_role, school: school)
          UserRole.create!(user: user, role: teacher_role, school: school)
          user
        end
        let(:admin3) do
          user = create(:user, first_name: 'Piotr', last_name: 'Wiśniewski', school: school)
          UserRole.create!(user: user, role: principal_role, school: school)
          UserRole.create!(user: user, role: teacher_role, school: school)
          user
        end
        let(:Authorization) { auth_token }

        before do
          principal
          school_manager
          admin1
          admin2
          admin3
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
                               roles: {
                                 type: :array,
                                 items: { type: :string }
                               },
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
          expect(json['data']['data'].length).to be >= 4 # principal, school_manager, admin1, admin2, admin3
          expect(json['data']['pagination']).to be_present

          # Verify roles are included
          admin2_data = json['data']['data'].find { |a| a['id'] == admin2.id.to_s }
          expect(admin2_data).to be_present
          expect(admin2_data['attributes']['roles']).to include('school_manager', 'teacher')
        end
      end

      response '200', 'filtered by search term' do
        let(:admin1) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user, role: principal_role, school: school)
          user
        end
        let(:admin2) do
          user = create(:user, first_name: 'Anna', last_name: 'Nowak', school: school)
          UserRole.create!(user: user, role: school_manager_role, school: school)
          user
        end
        let(:Authorization) { auth_token }
        let(:search) { 'Jan' }

        before do
          principal
          school_manager
          admin1
          admin2
        end

        run_test! do
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['success']).to be true
          # Should find admin1 with name "Jan"
          found = json['data']['data'].find { |a| a['attributes']['first_name'] == 'Jan' }
          expect(found).to be_present
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

    post 'Create administration' do
      tags 'Management Administrations'
      produces 'application/json'
      consumes 'application/json'
      security [bearerAuth: []]

      parameter name: :administration, in: :body, schema: {
        type: :object,
        properties: {
          administration: {
            type: :object,
            properties: {
              first_name: { type: :string },
              last_name: { type: :string },
              email: { type: :string },
              roles: {
                type: :array,
                items: { type: :string, enum: %w[principal school_manager teacher] }
              },
              metadata: {
                type: :object,
                properties: {
                  phone: { type: :string }
                }
              }
            },
            required: %i[first_name last_name email roles]
          }
        }
      }

      response '201', 'administration created' do
        let(:Authorization) { auth_token }
        let(:administration) do
          {
            administration: {
              first_name: 'Jan',
              last_name: 'Kowalski',
              email: 'jan.kowalski@example.com',
              roles: %w[principal teacher],
              metadata: {
                phone: '+48 123 456 789'
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
                             roles: {
                               type: :array,
                               items: { type: :string }
                             },
                             phone: { type: :string, nullable: true }
                           }
                         }
                       }
                     }
                   }
                 }
               }

        before do
          principal_role
          school_manager_role
          teacher_role
          school
          principal # Ensure principal exists before test runs
        end

        run_test! do
          expect(response).to have_http_status(:created)
          json = JSON.parse(response.body)
          expect(json['success']).to be true
          expect(json['data']['data']['attributes']['first_name']).to eq('Jan')
          expect(json['data']['data']['attributes']['last_name']).to eq('Kowalski')

          # Verify roles were assigned
          created_user = User.find(json['data']['data']['id'])
          expect(created_user.school_id).to eq(school.id)
          expect(created_user.user_roles.joins(:role).where(roles: { key: 'principal' },
                                                            school: school).exists?).to be true
          expect(created_user.user_roles.joins(:role).where(roles: { key: 'teacher' },
                                                            school: school).exists?).to be true

          # Verify notification was created
          notification = Notification.find_by(
            notification_type: 'teacher_awaiting_approval',
            school: school,
            target_role: 'principal'
          )
          expect(notification).to be_present
        end
      end

      response '201', 'administration created with school_manager role' do
        let(:Authorization) { auth_token }
        let(:administration) do
          {
            administration: {
              first_name: 'Anna',
              last_name: 'Nowak',
              email: 'anna.nowak@example.com',
              roles: ['school_manager']
            }
          }
        end

        run_test! do
          expect(response).to have_http_status(:created)
          json = JSON.parse(response.body)
          created_user = User.find(json['data']['data']['id'])
          expect(created_user.user_roles.joins(:role).where(roles: { key: 'school_manager' },
                                                            school: school).exists?).to be true
        end
      end

      response '422', 'invalid request - missing required fields' do
        let(:Authorization) { auth_token }
        let(:administration) { { administration: { email: 'invalid-email' } } }

        run_test! do
          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)
          expect(json['success']).to be false
        end
      end

      response '201', 'administration created with only teacher role (no validation)' do
        # NOTE: CreateAdministration doesn't validate that at least one admin role is present
        # This test documents current behavior - user will be created but may not have admin roles
        let(:Authorization) { auth_token }
        let(:administration) do
          {
            administration: {
              first_name: 'Jan',
              last_name: 'Kowalski',
              email: 'jan.kowalski.teacher@example.com',
              roles: ['teacher'] # Only teacher, no principal or school_manager
            }
          }
        end

        run_test! do
          # Current implementation allows this - user is created but may not have admin roles
          # This might be a bug or intentional - documenting current behavior
          expect(response).to have_http_status(:created)
          json = JSON.parse(response.body)
          created_user = User.find(json['data']['data']['id'])
          # User will be created, but may not have admin roles assigned
          expect(created_user).to be_present
        end
      end
    end
  end

  path '/api/v1/management/administrations/{id}' do
    parameter name: :id, in: :path, type: :string, format: :uuid

    get 'Show administration' do
      tags 'Management Administrations'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'administration found' do
        let(:admin_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user, role: principal_role, school: school)
          UserRole.create!(user: user, role: teacher_role, school: school)
          user
        end
        let(:id) { admin_record.id }
        let(:Authorization) { auth_token }

        schema type: :object,
               properties: {
                 success: { type: :boolean },
                 data: {
                   type: :object,
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
                             school_id: { type: :string, format: :uuid },
                             roles: {
                               type: :array,
                               items: { type: :string }
                             },
                             phone: { type: :string, nullable: true }
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
          expect(json['success']).to be true
          expect(json['data']['data']['attributes']['first_name']).to eq('Jan')
          expect(json['data']['data']['attributes']['roles']).to include('principal', 'teacher')
        end
      end

      response '404', 'administration not found' do
        let(:id) { SecureRandom.uuid }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:not_found)
          json = JSON.parse(response.body)
          expect(json['success']).to be false
        end
      end

      response '404', 'administration from different school' do
        let(:other_school) { create(:school) }
        let(:other_admin) do
          user = create(:user, school: other_school)
          UserRole.create!(user: user, role: principal_role, school: other_school)
          user
        end
        let(:id) { other_admin.id }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    patch 'Update administration' do
      tags 'Management Administrations'
      produces 'application/json'
      consumes 'application/json'
      security [bearerAuth: []]

      parameter name: :administration, in: :body, schema: {
        type: :object,
        properties: {
          administration: {
            type: :object,
            properties: {
              first_name: { type: :string },
              last_name: { type: :string },
              email: { type: :string },
              roles: {
                type: :array,
                items: { type: :string, enum: %w[principal school_manager teacher] }
              },
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

      response '200', 'administration updated' do
        let(:admin_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school, phone: nil)
          UserRole.create!(user: user, role: principal_role, school: school)
          user
        end
        let(:id) { admin_record.id }
        let(:Authorization) { auth_token }
        let(:administration) do
          {
            administration: {
              first_name: 'Jan Updated',
              last_name: 'Kowalski Updated',
              roles: %w[principal school_manager teacher],
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
          expect(json['data']['data']['attributes']['last_name']).to eq('Kowalski Updated')
          expect(json['data']['data']['attributes']['phone']).to eq('+48 999 888 777')
          expect(json['data']['data']['attributes']['roles']).to include('principal', 'school_manager', 'teacher')

          # Verify roles were updated
          admin_record.reload
          expect(admin_record.user_roles.joins(:role).where(roles: { key: 'principal' },
                                                            school: school).exists?).to be true
          expect(admin_record.user_roles.joins(:role).where(roles: { key: 'school_manager' },
                                                            school: school).exists?).to be true
          expect(admin_record.user_roles.joins(:role).where(roles: { key: 'teacher' },
                                                            school: school).exists?).to be true
        end
      end

      response '200', 'administration roles updated - remove teacher role' do
        let(:admin_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user, role: principal_role, school: school)
          UserRole.create!(user: user, role: teacher_role, school: school)
          user
        end
        let(:id) { admin_record.id }
        let(:Authorization) { auth_token }
        let(:administration) do
          {
            administration: {
              roles: ['principal'] # Remove teacher role
            }
          }
        end

        run_test! do
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['data']['data']['attributes']['roles']).to eq(['principal'])

          # Verify teacher role was removed
          admin_record.reload
          expect(admin_record.user_roles.joins(:role).where(roles: { key: 'teacher' },
                                                            school: school).exists?).to be false
        end
      end

      response '422', 'invalid request - no administration roles' do
        let(:admin_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user, role: principal_role, school: school)
          user
        end
        let(:id) { admin_record.id }
        let(:Authorization) { auth_token }
        let(:administration) do
          {
            administration: {
              roles: ['teacher'] # Only teacher, no principal or school_manager
            }
          }
        end

        run_test! do
          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)
          expect(json['success']).to be false
          expect(json['errors']).to be_present
        end
      end

      response '403', 'cannot update own roles' do
        let(:id) { school_manager.id }
        let(:Authorization) { auth_token }
        let(:administration) do
          {
            administration: {
              roles: %w[school_manager teacher] # Try to update own roles
            }
          }
        end

        run_test! do
          # User cannot change their own roles to prevent self-lockout
          expect(response).to have_http_status(:forbidden)
          json = JSON.parse(response.body)
          expect(json['errors']).to be_present
          expect(json['errors'].first).to include('własnych uprawnień')
        end
      end
    end

    delete 'Delete administration' do
      tags 'Management Administrations'
      produces 'application/json'
      security [bearerAuth: []]

      response '204', 'administration deleted' do
        let(:admin_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user, role: principal_role, school: school)
          user
        end
        let(:id) { admin_record.id }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:no_content)
          expect(User.find_by(id: admin_record.id)).to be_nil
        end
      end

      response '422', 'cannot delete self' do
        let(:id) { school_manager.id }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)
          expect(json['errors']).to be_present
          expect(json['errors'].first).to include('własnego konta')
          expect(User.find_by(id: school_manager.id)).to be_present
        end
      end

      response '404', 'administration not found' do
        let(:id) { SecureRandom.uuid }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  path '/api/v1/management/administrations/{id}/resend_invite' do
    parameter name: :id, in: :path, type: :string, format: :uuid

    post 'Resend invite to administration' do
      tags 'Management Administrations'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'invite resent' do
        let(:admin_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school, confirmed_at: nil)
          UserRole.create!(user: user, role: principal_role, school: school)
          user
        end
        let(:id) { admin_record.id }
        let(:Authorization) { auth_token }

        schema type: :object,
               properties: {
                 success: { type: :boolean },
                 message: { type: :string }
               }

        run_test! do
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['success']).to be true
        end
      end

      response '404', 'administration not found' do
        let(:id) { SecureRandom.uuid }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  path '/api/v1/management/administrations/{id}/lock' do
    parameter name: :id, in: :path, type: :string, format: :uuid

    post 'Lock or unlock administration account' do
      tags 'Management Administrations'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'administration account locked' do
        let(:admin_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user, role: principal_role, school: school)
          user
        end
        let(:id) { admin_record.id }
        let(:Authorization) { auth_token }

        schema type: :object,
               properties: {
                 success: { type: :boolean },
                 data: {
                   type: :object,
                   properties: {
                     data: {
                       type: :object,
                       properties: {
                         id: { type: :string, format: :uuid },
                         attributes: {
                           type: :object,
                           properties: {
                             is_locked: { type: :boolean },
                             locked_at: { type: :string, nullable: true }
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
          expect(json['success']).to be true

          admin_record.reload
          expect(admin_record.locked_at).to be_present
          expect(json['data']['data']['attributes']['is_locked']).to be true
        end
      end

      response '200', 'administration account unlocked' do
        let(:admin_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school, locked_at: Time.current)
          UserRole.create!(user: user, role: principal_role, school: school)
          user
        end
        let(:id) { admin_record.id }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['success']).to be true

          admin_record.reload
          expect(admin_record.locked_at).to be_nil
          expect(json['data']['data']['attributes']['is_locked']).to be false
        end
      end

      response '422', 'cannot lock self' do
        let(:id) { school_manager.id }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)
          expect(json['errors']).to be_present
          expect(json['errors'].first).to include('własnego konta')
        end
      end

      response '404', 'administration not found' do
        let(:id) { SecureRandom.uuid }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
