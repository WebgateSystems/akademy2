# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Teachers API', type: :request do
  include ApplicationTestHelper

  let(:admin_role) { Role.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' } }
  let(:admin_user) do
    user = create(:user)
    UserRole.find_or_create_by!(user: user, role: admin_role) { |ur| ur.school = user.school }
    user
  end
  let(:auth_token) { "Bearer #{generate_token(admin_user)}" }
  let!(:teacher_role) { Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }
  let(:school) { create(:school) }

  path '/api/v1/teachers' do
    get 'List teachers' do
      tags 'Teachers'
      produces 'application/json'
      security [bearerAuth: []]

      parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number'
      parameter name: :per_page, in: :query, type: :integer, required: false, description: 'Items per page'
      parameter name: :search, in: :query, type: :string, required: false, description: 'Search term'
      parameter name: :status, in: :query, type: :string, required: false,
                description: 'Filter by status (active/inactive)'

      response '200', 'teachers list' do
        before do
          user1 = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user1, role: teacher_role, school: school)
          user2 = create(:user, first_name: 'Anna', last_name: 'Nowak', school: school)
          UserRole.create!(user: user2, role: teacher_role, school: school)
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
                           school_id: { type: :string, format: :uuid, nullable: true },
                           school_name: { type: :string, nullable: true },
                           phone: { type: :string, nullable: true },
                           birth_date: { type: :string, nullable: true },
                           subjects: { type: :array, items: { type: :string } },
                           locked_at: { type: :string, nullable: true },
                           is_locked: { type: :boolean },
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

        run_test! do
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['data']).to be_an(Array)
          expect(json['data'].length).to be >= 2
          expect(json['pagination']).to be_present
        end
      end

      response '401', 'unauthorized' do
        let(:Authorization) { nil }

        run_test! do
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end

    post 'Create teacher' do
      tags 'Teachers'
      produces 'application/json'
      consumes 'application/json'
      security [bearerAuth: []]

      parameter name: :teacher, in: :body, schema: {
        type: :object,
        properties: {
          teacher: {
            type: :object,
            properties: {
              first_name: { type: :string },
              last_name: { type: :string },
              email: { type: :string },
              school_id: { type: :string, format: :uuid },
              metadata: {
                type: :object,
                properties: {
                  phone: { type: :string },
                  birth_date: { type: :string }
                }
              }
            },
            required: %i[first_name last_name email school_id]
          }
        }
      }

      response '201', 'teacher created' do
        let(:Authorization) { auth_token }
        let(:teacher) do
          {
            teacher: {
              first_name: 'Jan',
              last_name: 'Kowalski',
              email: 'jan.kowalski@example.com',
              school_id: school.id,
              metadata: {
                phone: '+48 123 456 789',
                birth_date: '15.03.1985'
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

          # Verify teacher role was assigned
          created_user = User.find(json['data']['id'])

          # Verify school is set
          expect(created_user.school_id).to eq(school.id)
          expect(created_user.school).to eq(school), 'School association should be loaded'

          # Check if teacher role exists in database
          teacher_role_db = Role.find_by(key: 'teacher')
          expect(teacher_role_db).to be_present, 'Teacher role should exist in database'

          # Check UserRole directly - use joins to find by role key
          user_role = UserRole.joins(:role).find_by(user: created_user, roles: { key: 'teacher' })

          # If UserRole doesn't exist, provide detailed error message
          unless user_role
            # Get all UserRoles for this user for debugging
            all_user_roles = UserRole.where(user: created_user).includes(:role)
            role_keys = all_user_roles.map { |ur| ur.role.key }

            # Check if school association is loaded
            school_loaded = created_user.association(:school).loaded?
            school_value = created_user.school

            error_msg = format(
              'UserRole should be created for teacher. User ID: %s, School ID: %s, ' \
              'School loaded: %s, School value: %s, Teacher role exists: %s, All user roles: %s',
              created_user.id, created_user.school_id, school_loaded, school_value&.id,
              teacher_role_db.present?, role_keys.inspect
            )
            raise error_msg
          end

          expect(user_role.school).to eq(school)
          # Also verify through roles association
          expect(created_user.roles.pluck(:key)).to include('teacher')
        end
      end

      response '422', 'invalid request' do
        let(:Authorization) { auth_token }
        let(:teacher) { { teacher: { email: 'invalid-email', school_id: school.id } } }

        run_test! do
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  path '/api/v1/teachers/{id}' do
    parameter name: :id, in: :path, type: :string, format: :uuid

    get 'Show teacher' do
      tags 'Teachers'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'teacher found' do
        let(:teacher_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user, role: teacher_role, school: school)
          user
        end
        let(:id) { teacher_record.id }
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
                         school_id: { type: :string, format: :uuid, nullable: true },
                         school_name: { type: :string, nullable: true },
                         phone: { type: :string, nullable: true },
                         birth_date: { type: :string, nullable: true },
                         subjects: { type: :array, items: { type: :string } },
                         locked_at: { type: :string, nullable: true },
                         is_locked: { type: :boolean }
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

      response '404', 'teacher not found' do
        let(:id) { SecureRandom.uuid }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    patch 'Update teacher' do
      tags 'Teachers'
      produces 'application/json'
      consumes 'application/json'
      security [bearerAuth: []]

      parameter name: :teacher, in: :body, schema: {
        type: :object,
        properties: {
          teacher: {
            type: :object,
            properties: {
              first_name: { type: :string },
              last_name: { type: :string },
              email: { type: :string },
              school_id: { type: :string, format: :uuid },
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

      response '200', 'teacher updated' do
        let(:teacher_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user, role: teacher_role, school: school)
          user
        end
        let(:id) { teacher_record.id }
        let(:Authorization) { auth_token }
        let(:teacher) do
          {
            teacher: {
              first_name: 'Jan',
              last_name: 'Nowak',
              email: teacher_record.email,
              school_id: school.id,
              metadata: {
                phone: '+48 999 888 777',
                birth_date: '20.05.1990'
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
        let(:teacher_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user, role: teacher_role, school: school)
          user
        end
        let(:id) { teacher_record.id }
        let(:Authorization) { auth_token }
        let(:teacher) { { teacher: { email: 'invalid-email' } } }

        run_test! do
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    delete 'Delete teacher' do
      tags 'Teachers'
      security [bearerAuth: []]

      response '204', 'teacher deleted' do
        let!(:teacher_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user, role: teacher_role, school: school)
          user
        end
        let(:id) { teacher_record.id }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:no_content)
          expect(User.find_by(id: id)).to be_nil
        end
      end

      response '404', 'teacher not found' do
        let(:id) { SecureRandom.uuid }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  path '/api/v1/teachers/{id}/resend_invite' do
    parameter name: :id, in: :path, type: :string, format: :uuid

    post 'Resend invite to teacher' do
      tags 'Teachers'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'invite resent' do
        let(:teacher_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school, confirmed_at: nil)
          UserRole.create!(user: user, role: teacher_role, school: school)
          user
        end
        let(:id) { teacher_record.id }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['message']).to be_present
        end
      end

      response '404', 'teacher not found' do
        let(:id) { SecureRandom.uuid }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  path '/api/v1/teachers/{id}/lock' do
    parameter name: :id, in: :path, type: :string, format: :uuid

    post 'Lock or unlock teacher account' do
      tags 'Teachers'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'teacher locked' do
        let(:teacher_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user, role: teacher_role, school: school)
          user
        end
        let(:id) { teacher_record.id }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['message']).to be_present
          teacher_record.reload
          expect(teacher_record.locked_at).to be_present
        end
      end

      response '200', 'teacher unlocked' do
        let(:teacher_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school, locked_at: Time.current)
          UserRole.create!(user: user, role: teacher_role, school: school)
          user
        end
        let(:id) { teacher_record.id }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['message']).to be_present
          teacher_record.reload
          expect(teacher_record.locked_at).to be_nil
        end
      end

      response '404', 'teacher not found' do
        let(:id) { SecureRandom.uuid }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
