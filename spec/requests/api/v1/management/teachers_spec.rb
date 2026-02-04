# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API V1 Management Teachers', type: :request do
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

  describe 'GET /api/v1/management/teachers' do
    it 'returns 200' do
      allow(Api::V1::Management::ListTeachers).to receive(:call).and_return(success_result)
      get '/api/v1/management/teachers', headers: headers
      expect(response).to have_http_status(:ok)
    end

    it 'returns 401 without token' do
      get '/api/v1/management/teachers'
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 403 when forbidden' do
      result = double(status: :forbidden, success?: false, message: ['forbidden'])
      allow(Api::V1::Management::ListTeachers).to receive(:call).and_return(result)
      get '/api/v1/management/teachers', headers: headers
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /api/v1/management/teachers/:id' do
    it 'returns 200' do
      allow(Api::V1::Management::ShowTeacher).to receive(:call).and_return(success_result)
      get '/api/v1/management/teachers/123', headers: headers
      expect(response).to have_http_status(:ok)
    end

    it 'returns 404 when not found' do
      result = double(status: :not_found, success?: false, message: ['Not found'])
      allow(Api::V1::Management::ShowTeacher).to receive(:call).and_return(result)
      get '/api/v1/management/teachers/invalid', headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 401 without token' do
      get '/api/v1/management/teachers/123'
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST /api/v1/management/teachers' do
    it 'returns 201 on success' do
      result = success_result(status: :created)
      allow(Api::V1::Management::CreateTeacher).to receive(:call).and_return(result)

      post '/api/v1/management/teachers', headers: headers
      expect(response).to have_http_status(:created)
    end

    it 'returns 422 on validation error' do
      result = double(status: :unprocessable_entity, success?: false, message: ['Error'])
      allow(Api::V1::Management::CreateTeacher).to receive(:call).and_return(result)

      post '/api/v1/management/teachers', headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns 401 without token' do
      post '/api/v1/management/teachers'
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'PATCH /api/v1/management/teachers/:id' do
    it 'returns 200 on success' do
      allow(Api::V1::Management::UpdateTeacher).to receive(:call).and_return(success_result)
      patch '/api/v1/management/teachers/123', headers: headers
      expect(response).to have_http_status(:ok)
    end

    it 'returns 404 when not found' do
      result = double(status: :not_found, success?: false, message: ['Not found'])
      allow(Api::V1::Management::UpdateTeacher).to receive(:call).and_return(result)
      patch '/api/v1/management/teachers/invalid', headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 401 without token' do
      patch '/api/v1/management/teachers/123'
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'DELETE /api/v1/management/teachers/:id' do
    it 'returns 204 on success' do
      result = success_result(status: :no_content)
      allow(Api::V1::Management::DestroyTeacher).to receive(:call).and_return(result)
      delete '/api/v1/management/teachers/123', headers: headers
      expect(response).to have_http_status(:no_content)
    end

    it 'returns 404 when not found' do
      result = double(status: :not_found, success?: false, message: ['Not found'])
      allow(Api::V1::Management::DestroyTeacher).to receive(:call).and_return(result)
      delete '/api/v1/management/teachers/invalid', headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 401 without token' do
      delete '/api/v1/management/teachers/123'
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST /api/v1/management/teachers/:id/resend_invite' do
    it 'returns 200 on success' do
      allow(Api::V1::Management::ResendInviteTeacher).to receive(:call).and_return(success_result)
      post '/api/v1/management/teachers/123/resend_invite', headers: headers
      expect(response).to have_http_status(:ok)
    end

    it 'returns 404 when not found' do
      result = double(status: :not_found, success?: false, message: ['Not found'])
      allow(Api::V1::Management::ResendInviteTeacher).to receive(:call).and_return(result)
      post '/api/v1/management/teachers/invalid/resend_invite', headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 401 without token' do
      post '/api/v1/management/teachers/123/resend_invite'
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST /api/v1/management/teachers/:id/lock' do
    it 'returns 200 on success' do
      allow(Api::V1::Management::LockTeacher).to receive(:call).and_return(success_result)
      post '/api/v1/management/teachers/123/lock', headers: headers
      expect(response).to have_http_status(:ok)
    end

    it 'returns 404 when not found' do
      result = double(status: :not_found, success?: false, message: ['Not found'])
      allow(Api::V1::Management::LockTeacher).to receive(:call).and_return(result)
      post '/api/v1/management/teachers/invalid/lock', headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 401 without token' do
      post '/api/v1/management/teachers/123/lock'
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST /api/v1/management/teachers/:id/approve' do
    it 'returns 200 on success' do
      allow(Api::V1::Management::ApproveTeacher).to receive(:call).and_return(success_result)
      post '/api/v1/management/teachers/123/approve', headers: headers
      expect(response).to have_http_status(:ok)
    end

    it 'returns 404 when not found' do
      result = double(status: :not_found, success?: false, message: ['Not found'])
      allow(Api::V1::Management::ApproveTeacher).to receive(:call).and_return(result)
      post '/api/v1/management/teachers/invalid/approve', headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 401 without token' do
      post '/api/v1/management/teachers/123/approve'
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST /api/v1/management/teachers/:id/decline' do
    it 'returns 204 on success' do
      result = success_result(status: :no_content)
      allow(Api::V1::Management::DestroyTeacher).to receive(:call).and_return(result)
      post '/api/v1/management/teachers/123/decline', headers: headers
      expect(response).to have_http_status(:no_content)
    end

    it 'returns 404 when not found' do
      result = double(status: :not_found, success?: false, message: ['Not found'])
      allow(Api::V1::Management::DestroyTeacher).to receive(:call).and_return(result)
      post '/api/v1/management/teachers/invalid/decline', headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 401 without token' do
      post '/api/v1/management/teachers/123/decline'
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
# frozen_string_literal: true

require 'swagger_helper'

# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe 'Management Teachers API', type: :request do
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

  path '/api/v1/management/teachers' do
    get 'List teachers' do
      tags 'Management Teachers'
      produces 'application/json'
      security [bearerAuth: []]

      parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number'
      parameter name: :per_page, in: :query, type: :integer, required: false, description: 'Items per page'
      parameter name: :search, in: :query, type: :string, required: false, description: 'Search term'

      response '200', 'teachers list' do
        let(:teacher1) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user, role: teacher_role, school: school)
          TeacherSchoolEnrollment.create!(teacher: user, school: school, status: :approved)
          user
        end
        let(:teacher2) do
          user = create(:user, first_name: 'Anna', last_name: 'Nowak', school: school)
          UserRole.create!(user: user, role: teacher_role, school: school)
          UserRole.create!(user: user, role: school_manager_role, school: school)
          TeacherSchoolEnrollment.create!(teacher: user, school: school, status: :approved)
          user
        end
        let(:Authorization) { auth_token }

        before do
          principal
          school_manager
          teacher1
          teacher2
          principal_role
          school_manager_role
          teacher_role
          school
          principal
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
                               subjects: { type: :array, items: { type: :string } },
                               locked_at: { type: :string, nullable: true },
                               is_locked: { type: :boolean },
                               is_confirmed: { type: :boolean },
                               confirmed_at: { type: :string, nullable: true },
                               enrollment_status: { type: :string },
                               enrollment_id: { type: :string, format: :uuid, nullable: true },
                               is_school_manager: { type: :boolean },
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

    post 'Create teacher' do
      tags 'Management Teachers'
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
              is_school_manager: { type: :boolean, description: 'Grant school manager role' },
              metadata: {
                type: :object,
                properties: {
                  phone: { type: :string }
                }
              }
            },
            required: %i[first_name last_name email]
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
              email: 'jan.kowalski.teacher@example.com',
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
                             phone: { type: :string, nullable: true },
                             is_school_manager: { type: :boolean }
                           }
                         }
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

          # Verify teacher role was assigned and enrollment created
          created_user = User.find(json['data']['data']['id'])
          expect(created_user.school_id).to eq(school.id)
          expect(created_user.user_roles.joins(:role).where(roles: { key: 'teacher' },
                                                            school: school).exists?).to be true
          expect(TeacherSchoolEnrollment.find_by(teacher: created_user, school: school,
                                                 status: :approved)).to be_present
        end
      end

      response '201', 'teacher created with school_manager role' do
        let(:Authorization) { auth_token }
        let(:teacher) do
          {
            teacher: {
              first_name: 'Anna',
              last_name: 'Nowak',
              email: 'anna.nowak.teacher@example.com',
              is_school_manager: true
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
        let(:teacher) { { teacher: { email: 'invalid-email' } } }

        run_test! do
          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)
          expect(json['success']).to be false
        end
      end
    end
  end

  path '/api/v1/management/teachers/{id}' do
    parameter name: :id, in: :path, type: :string, format: :uuid

    get 'Show teacher' do
      tags 'Management Teachers'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'teacher found' do
        let(:teacher_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user, role: teacher_role, school: school)
          TeacherSchoolEnrollment.create!(teacher: user, school: school, status: :approved)
          user
        end
        let(:id) { teacher_record.id }
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
                             phone: { type: :string, nullable: true },
                             is_school_manager: { type: :boolean }
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
        end
      end

      response '404', 'teacher not found' do
        let(:id) { SecureRandom.uuid }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:not_found)
          json = JSON.parse(response.body)
          expect(json['success']).to be false
        end
      end

      response '404', 'teacher from different school' do
        let(:other_school) { create(:school) }
        let(:other_teacher) do
          user = create(:user, school: other_school)
          UserRole.create!(user: user, role: teacher_role, school: other_school)
          user
        end
        let(:id) { other_teacher.id }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    patch 'Update teacher' do
      tags 'Management Teachers'
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
              email: { type: :string, description: 'Email can be changed without Devise confirmation' },
              password: { type: :string, description: 'New password (leave empty to keep current)' },
              password_confirmation: { type: :string,
                                       description: 'Password confirmation (required if password is provided)' },
              is_school_manager: { type: :boolean, description: 'Grant or revoke school manager role' },
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

      response '200', 'teacher updated' do
        let(:teacher_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school, phone: nil)
          UserRole.create!(user: user, role: teacher_role, school: school)
          TeacherSchoolEnrollment.create!(teacher: user, school: school, status: :approved)
          user
        end
        let(:id) { teacher_record.id }
        let(:Authorization) { auth_token }
        let(:teacher) do
          {
            teacher: {
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
          expect(json['data']['data']['attributes']['last_name']).to eq('Kowalski Updated')
          expect(json['data']['data']['attributes']['phone']).to eq('+48 999 888 777')
        end
      end

      response '200', 'teacher promoted to school manager' do
        let(:teacher_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user, role: teacher_role, school: school)
          TeacherSchoolEnrollment.create!(teacher: user, school: school, status: :approved)
          user
        end
        let(:id) { teacher_record.id }
        let(:Authorization) { auth_token }
        let(:teacher) do
          {
            teacher: {
              is_school_manager: true
            }
          }
        end

        run_test! do
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['data']['data']['attributes']['is_school_manager']).to be true

          teacher_record.reload
          expect(teacher_record.user_roles.joins(:role).where(roles: { key: 'school_manager' },
                                                              school: school).exists?).to be true
        end
      end

      response '200', 'teacher email updated without confirmation' do
        let(:teacher_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', email: 'old@example.com', school: school)
          UserRole.create!(user: user, role: teacher_role, school: school)
          TeacherSchoolEnrollment.create!(teacher: user, school: school, status: :approved)
          user
        end
        let(:id) { teacher_record.id }
        let(:Authorization) { auth_token }
        let(:teacher) do
          {
            teacher: {
              email: 'new@example.com'
            }
          }
        end

        run_test! do
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['data']['data']['attributes']['email']).to eq('new@example.com')

          teacher_record.reload
          expect(teacher_record.email).to eq('new@example.com')
          expect(teacher_record.unconfirmed_email).to be_nil
        end
      end

      response '200', 'teacher password updated' do
        let(:teacher_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user, role: teacher_role, school: school)
          TeacherSchoolEnrollment.create!(teacher: user, school: school, status: :approved)
          user
        end
        let(:id) { teacher_record.id }
        let(:Authorization) { auth_token }
        let(:teacher) do
          {
            teacher: {
              password: 'newpassword123',
              password_confirmation: 'newpassword123'
            }
          }
        end

        run_test! do
          expect(response).to have_http_status(:ok)
          teacher_record.reload
          expect(teacher_record.valid_password?('newpassword123')).to be true
        end
      end

      response '404', 'teacher not found' do
        let(:id) { SecureRandom.uuid }
        let(:Authorization) { auth_token }
        let(:teacher) { { teacher: { first_name: 'Updated' } } }

        run_test! do
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    delete 'Delete teacher' do
      tags 'Management Teachers'
      produces 'application/json'
      security [bearerAuth: []]

      response '204', 'teacher removed from school' do
        let(:teacher_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user, role: teacher_role, school: school)
          TeacherSchoolEnrollment.create!(teacher: user, school: school, status: :approved)
          user
        end
        let(:id) { teacher_record.id }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:no_content)
          # Teacher is removed from school but user account is kept
          expect(TeacherSchoolEnrollment.find_by(teacher: teacher_record, school: school)).to be_nil
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

  path '/api/v1/management/teachers/{id}/resend_invite' do
    parameter name: :id, in: :path, type: :string, format: :uuid

    post 'Resend invite to teacher' do
      tags 'Management Teachers'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'invite resent' do
        let(:teacher_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school, confirmed_at: nil)
          UserRole.create!(user: user, role: teacher_role, school: school)
          TeacherSchoolEnrollment.create!(teacher: user, school: school, status: :approved)
          user
        end
        let(:id) { teacher_record.id }
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

      response '404', 'teacher not found' do
        let(:id) { SecureRandom.uuid }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  path '/api/v1/management/teachers/{id}/lock' do
    parameter name: :id, in: :path, type: :string, format: :uuid

    post 'Lock or unlock teacher account' do
      tags 'Management Teachers'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'teacher account locked' do
        let(:teacher_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user, role: teacher_role, school: school)
          TeacherSchoolEnrollment.create!(teacher: user, school: school, status: :approved)
          user
        end
        let(:id) { teacher_record.id }
        let(:Authorization) { auth_token }

        schema type: :object,
               properties: {
                 success: { type: :boolean },
                 data: {
                   type: :object,
                   properties: {
                     message: { type: :string }
                   }
                 }
               }

        run_test! do
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['success']).to be true

          teacher_record.reload
          expect(teacher_record.locked_at).to be_present
        end
      end

      response '200', 'teacher account unlocked' do
        let(:teacher_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school, locked_at: Time.current)
          UserRole.create!(user: user, role: teacher_role, school: school)
          TeacherSchoolEnrollment.create!(teacher: user, school: school, status: :approved)
          user
        end
        let(:id) { teacher_record.id }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['success']).to be true

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

  path '/api/v1/management/teachers/{id}/approve' do
    parameter name: :id, in: :path, type: :string, format: :uuid

    post 'Approve teacher enrollment' do
      tags 'Management Teachers'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'teacher approved' do
        let(:teacher_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user, role: teacher_role, school: school)
          TeacherSchoolEnrollment.create!(teacher: user, school: school, status: :pending)
          user
        end
        let(:id) { teacher_record.id }
        let(:Authorization) { auth_token }

        schema type: :object,
               properties: {
                 success: { type: :boolean },
                 data: {
                   type: :object
                 }
               }

        run_test! do
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['success']).to be true
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

  path '/api/v1/management/teachers/{id}/decline' do
    parameter name: :id, in: :path, type: :string, format: :uuid

    post 'Decline teacher enrollment' do
      tags 'Management Teachers'
      produces 'application/json'
      security [bearerAuth: []]

      response '204', 'teacher declined' do
        let(:teacher_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user, role: teacher_role, school: school)
          TeacherSchoolEnrollment.create!(teacher: user, school: school, status: :pending)
          user
        end
        let(:id) { teacher_record.id }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:no_content)
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
# rubocop:enable RSpec/MultipleMemoizedHelpers
