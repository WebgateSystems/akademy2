# frozen_string_literal: true

require 'swagger_helper'

# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe 'Management Parents API', type: :request do
  include ApplicationTestHelper

  let!(:parent_role) { Role.find_or_create_by!(key: 'parent') { |r| r.name = 'Parent' } }
  let!(:student_role) { Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' } }
  let!(:school_manager_role) { Role.find_or_create_by!(key: 'school_manager') { |r| r.name = 'School Manager' } }

  let(:school) { create(:school) }
  let(:academic_year) { school.academic_years.create!(year: '2024/2025', is_current: true, started_at: Date.current) }
  let(:school_class) do
    SchoolClass.create!(name: '1A', school: school, year: academic_year.year, qr_token: SecureRandom.uuid)
  end

  let(:school_manager) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: school_manager_role, school: school)
    user
  end
  let(:auth_token) { "Bearer #{generate_token(school_manager)}" }

  before do
    academic_year
    school_class
  end

  path '/api/v1/management/parents' do
    get 'List parents' do
      tags 'Management Parents'
      produces 'application/json'
      security [bearerAuth: []]

      parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number'
      parameter name: :per_page, in: :query, type: :integer, required: false, description: 'Items per page'
      parameter name: :search, in: :query, type: :string, required: false, description: 'Search term'

      response '200', 'parents list' do
        let(:parent1) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user, role: parent_role, school: school)
          user
        end
        let(:parent2) do
          user = create(:user, first_name: 'Anna', last_name: 'Nowak', school: school)
          UserRole.create!(user: user, role: parent_role, school: school)
          user
        end
        let(:Authorization) { auth_token }

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
                               first_name: { type: :string },
                               last_name: { type: :string },
                               email: { type: :string },
                               phone: { type: :string, nullable: true },
                               birthdate: { type: :string, nullable: true },
                               is_locked: { type: :boolean },
                               school_name: { type: :string, nullable: true },
                               students: {
                                 type: :array,
                                 items: {
                                   type: :object,
                                   properties: {
                                     id: { type: :string, format: :uuid },
                                     first_name: { type: :string },
                                     last_name: { type: :string },
                                     birthdate: { type: :string, nullable: true },
                                     class_name: { type: :string },
                                     relation: { type: :string }
                                   }
                                 }
                               }
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

        before do
          parent1
          parent2
        end

        run_test! do
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['success']).to be true
          expect(json['data']['data']).to be_an(Array)
          expect(json['data']['data'].length).to eq(2)
          expect(json['data']['pagination']).to be_present
        end
      end

      response '200', 'filtered by search term' do
        let(:parent1) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user, role: parent_role, school: school)
          user
        end
        let(:parent2) do
          user = create(:user, first_name: 'Anna', last_name: 'Nowak', school: school)
          UserRole.create!(user: user, role: parent_role, school: school)
          user
        end
        let(:Authorization) { auth_token }
        let(:search) { 'Jan' }

        before do
          parent1
          parent2
        end

        run_test! do
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['success']).to be true
          found = json['data']['data'].find { |p| p['attributes']['first_name'] == 'Jan' }
          expect(found).to be_present
        end
      end

      response '401', 'unauthorized' do
        let(:Authorization) { nil }

        run_test! do
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end

    post 'Create parent' do
      tags 'Management Parents'
      produces 'application/json'
      consumes 'application/json'
      security [bearerAuth: []]

      parameter name: :parent, in: :body, schema: {
        type: :object,
        properties: {
          parent: {
            type: :object,
            properties: {
              first_name: { type: :string },
              last_name: { type: :string },
              email: { type: :string },
              phone: { type: :string },
              relation: { type: :string, enum: %w[mother father guardian other] },
              student_ids: {
                type: :array,
                items: { type: :string, format: :uuid }
              }
            },
            required: %i[first_name last_name email]
          }
        }
      }

      response '201', 'parent created' do
        let(:student) do
          user = create(:user, school: school, birthdate: Date.new(2015, 3, 15))
          UserRole.create!(user: user, role: student_role, school: school)
          StudentClassEnrollment.create!(student: user, school_class: school_class, status: 'approved')
          user
        end
        let(:Authorization) { auth_token }
        let(:parent) do
          {
            parent: {
              first_name: 'Jan',
              last_name: 'Kowalski',
              email: 'jan.kowalski@example.com',
              phone: '+48 123 456 789',
              relation: 'father',
              student_ids: [student.id]
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
                             first_name: { type: :string },
                             last_name: { type: :string },
                             email: { type: :string },
                             phone: { type: :string, nullable: true },
                             is_locked: { type: :boolean },
                             students: { type: :array }
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

          created_user = User.find(json['data']['data']['id'])
          expect(created_user.school_id).to eq(school.id)
          expect(created_user.user_roles.joins(:role).where(roles: { key: 'parent' },
                                                            school: school).exists?).to be true
          expect(created_user.parent_student_links.count).to eq(1)
          expect(created_user.parent_student_links.first.relation).to eq('father')
        end
      end

      response '422', 'invalid request' do
        let(:Authorization) { auth_token }
        let(:parent) { { parent: { email: 'invalid' } } }

        run_test! do
          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)
          expect(json['success']).to be false
        end
      end
    end
  end

  path '/api/v1/management/parents/{id}' do
    parameter name: :id, in: :path, type: :string, format: :uuid

    get 'Show parent' do
      tags 'Management Parents'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'parent found' do
        let(:parent_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user, role: parent_role, school: school)
          user
        end
        let(:id) { parent_record.id }
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
                             first_name: { type: :string },
                             last_name: { type: :string },
                             email: { type: :string },
                             phone: { type: :string, nullable: true },
                             is_locked: { type: :boolean },
                             students: { type: :array }
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

      response '404', 'parent not found' do
        let(:id) { SecureRandom.uuid }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:not_found)
          json = JSON.parse(response.body)
          expect(json['success']).to be false
        end
      end
    end

    patch 'Update parent' do
      tags 'Management Parents'
      produces 'application/json'
      consumes 'application/json'
      security [bearerAuth: []]

      parameter name: :parent, in: :body, schema: {
        type: :object,
        properties: {
          parent: {
            type: :object,
            properties: {
              first_name: { type: :string },
              last_name: { type: :string },
              email: { type: :string },
              phone: { type: :string },
              relation: { type: :string, enum: %w[mother father guardian other] },
              student_ids: {
                type: :array,
                items: { type: :string, format: :uuid }
              }
            }
          }
        }
      }

      response '200', 'parent updated' do
        let(:parent_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user, role: parent_role, school: school)
          user
        end
        let(:id) { parent_record.id }
        let(:Authorization) { auth_token }
        let(:parent) do
          {
            parent: {
              first_name: 'Jan Updated',
              last_name: 'Kowalski Updated',
              phone: '+48 999 888 777'
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

      response '200', 'parent updated with students' do
        let(:student) do
          user = create(:user, school: school, birthdate: Date.new(2015, 3, 15))
          UserRole.create!(user: user, role: student_role, school: school)
          StudentClassEnrollment.create!(student: user, school_class: school_class, status: 'approved')
          user
        end
        let(:parent_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user, role: parent_role, school: school)
          user
        end
        let(:id) { parent_record.id }
        let(:Authorization) { auth_token }
        let(:parent) do
          {
            parent: {
              student_ids: [student.id],
              relation: 'mother'
            }
          }
        end

        run_test! do
          expect(response).to have_http_status(:ok)
          parent_record.reload
          expect(parent_record.parent_student_links.count).to eq(1)
          expect(parent_record.parent_student_links.first.relation).to eq('mother')
        end
      end

      response '404', 'parent not found' do
        let(:id) { SecureRandom.uuid }
        let(:Authorization) { auth_token }
        let(:parent) { { parent: { first_name: 'Test' } } }

        run_test! do
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    delete 'Delete parent' do
      tags 'Management Parents'
      produces 'application/json'
      security [bearerAuth: []]

      response '204', 'parent deleted' do
        let(:parent_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user, role: parent_role, school: school)
          user
        end
        let(:id) { parent_record.id }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:no_content)
          expect(User.find_by(id: parent_record.id)).to be_nil
        end
      end

      response '404', 'parent not found' do
        let(:id) { SecureRandom.uuid }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  path '/api/v1/management/parents/{id}/resend_invite' do
    parameter name: :id, in: :path, type: :string, format: :uuid

    post 'Resend invite to parent' do
      tags 'Management Parents'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'invite resent' do
        let(:parent_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school, confirmed_at: nil)
          UserRole.create!(user: user, role: parent_role, school: school)
          user
        end
        let(:id) { parent_record.id }
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

      response '404', 'parent not found' do
        let(:id) { SecureRandom.uuid }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  path '/api/v1/management/parents/{id}/lock' do
    parameter name: :id, in: :path, type: :string, format: :uuid

    post 'Lock or unlock parent account' do
      tags 'Management Parents'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'parent account locked' do
        let(:parent_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
          UserRole.create!(user: user, role: parent_role, school: school)
          user
        end
        let(:id) { parent_record.id }
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

          parent_record.reload
          expect(parent_record.locked_at).to be_present
          expect(json['data']['data']['attributes']['is_locked']).to be true
        end
      end

      response '200', 'parent account unlocked' do
        let(:parent_record) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school, locked_at: Time.current)
          UserRole.create!(user: user, role: parent_role, school: school)
          user
        end
        let(:id) { parent_record.id }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['success']).to be true

          parent_record.reload
          expect(parent_record.locked_at).to be_nil
          expect(json['data']['data']['attributes']['is_locked']).to be false
        end
      end

      response '404', 'parent not found' do
        let(:id) { SecureRandom.uuid }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  path '/api/v1/management/parents/search_students' do
    get 'Search students for parent assignment' do
      tags 'Management Parents'
      produces 'application/json'
      security [bearerAuth: []]

      parameter name: :q, in: :query, type: :string, required: true, description: 'Search term (min 2 characters)'

      response '200', 'students found' do
        let(:student1) do
          user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school,
                               birthdate: Date.new(2015, 3, 15))
          UserRole.create!(user: user, role: student_role, school: school)
          StudentClassEnrollment.create!(student: user, school_class: school_class, status: 'approved')
          user
        end
        let(:student2) do
          user = create(:user, first_name: 'Anna', last_name: 'Nowak', school: school, birthdate: Date.new(2016, 5, 20))
          UserRole.create!(user: user, role: student_role, school: school)
          StudentClassEnrollment.create!(student: user, school_class: school_class, status: 'approved')
          user
        end
        let(:Authorization) { auth_token }
        let(:q) { 'Jan' }

        before do
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
                           first_name: { type: :string },
                           last_name: { type: :string },
                           birthdate: { type: :string, nullable: true },
                           class_name: { type: :string },
                           email: { type: :string }
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
          expect(json['data']['data']).to be_an(Array)
          expect(json['data']['data'].length).to eq(1)
          expect(json['data']['data'].first['first_name']).to eq('Jan')
          expect(json['data']['data'].first['birthdate']).to eq('15.03.2015')
        end
      end

      response '422', 'missing search term' do
        let(:Authorization) { auth_token }
        let(:q) { '' }

        run_test! do
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
