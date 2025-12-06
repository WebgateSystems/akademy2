# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API V1 Students', type: :request do
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

  describe 'GET /api/v1/students' do
    it 'returns 200' do
      allow(Api::V1::Students::ListStudents).to receive(:call).and_return(success_result)
      get '/api/v1/students', headers: headers
      expect(response).to have_http_status(:ok)
    end

    it 'returns 401 without token' do
      get '/api/v1/students'
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'GET /api/v1/students/:id' do
    it 'returns 200' do
      allow(Api::V1::Students::ShowStudent).to receive(:call).and_return(success_result(form: {}))
      get "/api/v1/students/#{SecureRandom.uuid}", headers: headers
      expect(response).to have_http_status(:ok)
    end

    it 'returns 404 when not found' do
      result = double(status: :not_found, success?: false, message: 'Not found')
      allow(Api::V1::Students::ShowStudent).to receive(:call).and_return(result)
      get "/api/v1/students/#{SecureRandom.uuid}", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/students' do
    it 'returns 201 on success' do
      result = success_result(status: :created)
      allow(Api::V1::Students::CreateStudent).to receive(:call).and_return(result)
      post '/api/v1/students', headers: headers
      expect(response).to have_http_status(:created)
    end

    it 'returns 422 on validation error' do
      result = double(status: :unprocessable_entity, success?: false, message: ['Invalid'])
      allow(Api::V1::Students::CreateStudent).to receive(:call).and_return(result)
      post '/api/v1/students', headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH /api/v1/students/:id' do
    it 'returns 200 on success' do
      result = success_result(status: :ok)
      allow(Api::V1::Students::UpdateStudent).to receive(:call).and_return(result)
      patch "/api/v1/students/#{SecureRandom.uuid}", headers: headers
      expect(response).to have_http_status(:ok)
    end

    it 'returns 422 on validation error' do
      result = double(status: :unprocessable_entity, success?: false, message: ['Invalid'])
      allow(Api::V1::Students::UpdateStudent).to receive(:call).and_return(result)
      patch "/api/v1/students/#{SecureRandom.uuid}", headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'DELETE /api/v1/students/:id' do
    it 'returns 200 on success' do
      result = success_result(status: :ok)
      allow(Api::V1::Students::DestroyStudent).to receive(:call).and_return(result)
      delete "/api/v1/students/#{SecureRandom.uuid}", headers: headers
      expect(response).to have_http_status(:ok)
    end

    it 'returns 404 when not found' do
      result = double(status: :not_found, success?: false, message: 'Not found')
      allow(Api::V1::Students::DestroyStudent).to receive(:call).and_return(result)
      delete "/api/v1/students/#{SecureRandom.uuid}", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end
end

require 'swagger_helper'

RSpec.describe 'Students API', type: :request do
  include ApplicationTestHelper

  let(:admin_role) { Role.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' } }
  let(:admin_user) do
    user = create(:user)
    UserRole.find_or_create_by!(user: user, role: admin_role) { |ur| ur.school = user.school }
    user
  end
  let(:auth_token) { "Bearer #{generate_token(admin_user)}" }
  let!(:student_role) { Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' } }
  let(:school) { create(:school) }

  path '/api/v1/students' do
    get 'List students' do
      tags 'Students'
      produces 'application/json'
      security [bearerAuth: []]

      parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number'
      parameter name: :per_page, in: :query, type: :integer, required: false, description: 'Items per page'
      parameter name: :search, in: :query, type: :string, required: false, description: 'Search term'
      parameter name: :status, in: :query, type: :string, required: false,
                description: 'Filter by status (active/inactive)'

      response '200', 'students list' do
        before do
          user1 = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user1, role: student_role, school: school)
          user2 = create(:user, first_name: 'Anna', last_name: 'Nowak', school: school)
          UserRole.create!(user: user2, role: student_role, school: school)
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

    post 'Create student' do
      tags 'Students'
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

      response '201', 'student created' do
        let(:Authorization) { auth_token }
        let(:student) do
          {
            student: {
              first_name: 'Jan',
              last_name: 'Kowalski',
              email: 'jan.kowalski@example.com',
              school_id: school.id,
              metadata: {
                phone: '+48 123 456 789',
                birth_date: '15.03.2010'
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

          # Verify student role was assigned
          created_user = User.find(json['data']['id'])

          # Verify school is set
          expect(created_user.school_id).to eq(school.id)
          expect(created_user.school).to eq(school), 'School association should be loaded'

          # Check if student role exists in database
          student_role_db = Role.find_by(key: 'student')
          expect(student_role_db).to be_present, 'Student role should exist in database'

          # Check UserRole directly - use joins to find by role key
          user_role = UserRole.joins(:role).find_by(user: created_user, roles: { key: 'student' })

          # If UserRole doesn't exist, provide detailed error message
          unless user_role
            # Get all UserRoles for this user for debugging
            all_user_roles = UserRole.where(user: created_user).includes(:role)
            role_keys = all_user_roles.map { |ur| ur.role.key }

            # Check if school association is loaded
            school_loaded = created_user.association(:school).loaded?
            school_value = created_user.school

            error_msg = format(
              'UserRole should be created for student. User ID: %s, School ID: %s, ' \
              'School loaded: %s, School value: %s, Student role exists: %s, All user roles: %s',
              created_user.id, created_user.school_id, school_loaded, school_value&.id,
              student_role_db.present?, role_keys.inspect
            )
            raise error_msg
          end

          expect(user_role.school).to eq(school)
          # Also verify through roles association
          expect(created_user.roles.pluck(:key)).to include('student')
        end
      end

      response '422', 'invalid request' do
        let(:Authorization) { auth_token }
        let(:student) { { student: { email: 'invalid-email', school_id: school.id } } }

        run_test! do
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  path '/api/v1/students/{id}' do
    parameter name: :id, in: :path, type: :string, format: :uuid

    get 'Show student' do
      tags 'Students'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'student found' do
        let(:student_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user, role: student_role, school: school)
          user
        end
        let(:id) { student_record.id }
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
                         school_id: { type: :string, format: :uuid },
                         school_name: { type: :string, nullable: true },
                         phone: { type: :string, nullable: true },
                         birth_date: { type: :string, nullable: true },
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

      response '404', 'student not found' do
        let(:id) { SecureRandom.uuid }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    patch 'Update student' do
      tags 'Students'
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

      response '200', 'student updated' do
        let(:student_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user, role: student_role, school: school)
          user
        end
        let(:id) { student_record.id }
        let(:Authorization) { auth_token }
        let(:student) do
          {
            student: {
              first_name: 'Jan',
              last_name: 'Nowak',
              email: student_record.email,
              school_id: school.id,
              metadata: {
                phone: '+48 999 888 777',
                birth_date: '20.04.2011'
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
                         school_id: { type: :string, format: :uuid },
                         school_name: { type: :string, nullable: true },
                         phone: { type: :string, nullable: true },
                         birth_date: { type: :string, nullable: true }
                       }
                     }
                   }
                 }
               }

        run_test! do
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['data']['attributes']['last_name']).to eq('Nowak')
          expect(json['data']['attributes']['birth_date']).to eq('20.04.2011')
        end
      end

      response '422', 'invalid request' do
        let(:student_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user, role: student_role, school: school)
          user
        end
        let(:id) { student_record.id }
        let(:Authorization) { auth_token }
        let(:student) { { student: { email: 'invalid-email' } } }

        run_test! do
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    delete 'Delete student' do
      tags 'Students'
      security [bearerAuth: []]

      response '204', 'student deleted' do
        let!(:student_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user, role: student_role, school: school)
          user
        end
        let(:id) { student_record.id }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:no_content)
          expect(User.find_by(id: id)).to be_nil
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

  path '/api/v1/students/{id}/resend_invite' do
    parameter name: :id, in: :path, type: :string, format: :uuid

    post 'Resend invite to student' do
      tags 'Students'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'invite resent' do
        let(:student_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school, confirmed_at: nil)
          UserRole.create!(user: user, role: student_role, school: school)
          user
        end
        let(:id) { student_record.id }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['message']).to be_present
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

  path '/api/v1/students/{id}/lock' do
    parameter name: :id, in: :path, type: :string, format: :uuid

    post 'Lock or unlock student account' do
      tags 'Students'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'student locked' do
        let(:student_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user, role: student_role, school: school)
          user
        end
        let(:id) { student_record.id }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['message']).to be_present
          student_record.reload
          expect(student_record.locked_at).to be_present
        end
      end

      response '200', 'student unlocked' do
        let(:student_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school, locked_at: Time.current)
          UserRole.create!(user: user, role: student_role, school: school)
          user
        end
        let(:id) { student_record.id }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['message']).to be_present
          student_record.reload
          expect(student_record.locked_at).to be_nil
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
end
