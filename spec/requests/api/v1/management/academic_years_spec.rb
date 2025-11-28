# frozen_string_literal: true

require 'swagger_helper'

# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe 'Management Academic Years API', type: :request do
  include ApplicationTestHelper

  let!(:principal_role) { Role.find_or_create_by!(key: 'principal') { |r| r.name = 'Principal' } }
  let(:principal) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: principal_role, school: school)
    user
  end
  let!(:school_manager_role) { Role.find_or_create_by!(key: 'school_manager') { |r| r.name = 'School Manager' } }

  let(:school) { create(:school) }
  let(:school_manager) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: school_manager_role, school: school)
    user
  end
  let(:auth_token) { "Bearer #{generate_token(school_manager)}" }

  path '/api/v1/management/academic_years' do
    get 'List academic years' do
      tags 'Management Academic Years'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'academic years list' do
        let(:year1) { AcademicYear.create!(school: school, year: '2023/2024', is_current: false) }
        let(:year2) { AcademicYear.create!(school: school, year: '2024/2025', is_current: false) }
        let(:year3) { AcademicYear.create!(school: school, year: '2025/2026', is_current: true) }
        let(:Authorization) { auth_token }

        before do
          principal
          school_manager
          year1
          year2
          year3
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
                               year: { type: :string },
                               school_id: { type: :string, format: :uuid },
                               school_name: { type: :string, nullable: true },
                               is_current: { type: :boolean },
                               started_at: { type: :string, nullable: true, format: :date },
                               ended_at: { type: :string, nullable: true, format: :date },
                               classes_count: { type: :integer },
                               created_at: { type: :string },
                               updated_at: { type: :string }
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
          expect(json['success']).to be true
          expect(json['data']['data']).to be_an(Array)
          expect(json['data']['data'].length).to eq(3)
          # Check ordering (ascending by start year)
          years = json['data']['data'].map { |item| item['attributes']['year'] }
          expect(years).to eq(['2023/2024', '2024/2025', '2025/2026'])
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

    post 'Create academic year' do
      tags 'Management Academic Years'
      produces 'application/json'
      consumes 'application/json'
      security [bearerAuth: []]

      parameter name: :academic_year, in: :body, schema: {
        type: :object,
        properties: {
          academic_year: {
            type: :object,
            properties: {
              year: { type: :string, example: '2025/2026' },
              is_current: { type: :boolean, example: false },
              started_at: { type: :string, format: :date, nullable: true }
            },
            required: [:year]
          }
        }
      }

      response '201', 'academic year created' do
        let(:Authorization) { auth_token }
        let(:academic_year) do
          {
            academic_year: {
              year: '2027/2028',
              is_current: false
            }
          }
        end

        before do
          principal
          school_manager
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
                             year: { type: :string },
                             school_id: { type: :string, format: :uuid },
                             is_current: { type: :boolean },
                             started_at: { type: :string, nullable: true, format: :date }
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
          expect(json['data']['data']['attributes']['year']).to eq('2027/2028')
          expect(json['data']['data']['attributes']['is_current']).to be false
          # Check that started_at was auto-calculated
          expect(json['data']['data']['attributes']['started_at']).to eq('2027-09-01')
        end
      end

      response '422', 'invalid year format' do
        let(:Authorization) { auth_token }
        let(:academic_year) do
          {
            academic_year: {
              year: '2025/2028',
              is_current: false
            }
          }
        end

        before do
          principal
          school_manager
        end

        run_test! do
          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)
          expect(json['success']).to be false
          expect(json['errors']).to be_an(Array)
        end
      end

      response '422', 'duplicate year' do
        let(:Authorization) { auth_token }
        let(:academic_year) do
          {
            academic_year: {
              year: '2026/2027',
              is_current: false
            }
          }
        end

        before do
          principal
          school_manager
          AcademicYear.create!(school: school, year: '2026/2027', is_current: false)
        end

        run_test! do
          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)
          expect(json['success']).to be false
          expect(json['errors']).to be_an(Array)
        end
      end
    end
  end

  path '/api/v1/management/academic_years/{id}' do
    parameter name: :id, in: :path, type: :string, description: 'Academic year ID'

    get 'Show academic year' do
      tags 'Management Academic Years'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'academic year found' do
        let(:academic_year) { AcademicYear.create!(school: school, year: '2024/2025', is_current: false) }
        let(:id) { academic_year.id }
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
                             year: { type: :string },
                             school_id: { type: :string, format: :uuid },
                             is_current: { type: :boolean },
                             started_at: { type: :string, nullable: true, format: :date }
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
          expect(json['data']['data']['attributes']['year']).to eq('2024/2025')
        end
      end

      response '404', 'academic year not found' do
        let(:id) { SecureRandom.uuid }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:not_found)
          json = JSON.parse(response.body)
          expect(json['success']).to be false
        end
      end
    end

    patch 'Update academic year' do
      tags 'Management Academic Years'
      produces 'application/json'
      consumes 'application/json'
      security [bearerAuth: []]

      parameter name: :academic_year, in: :body, schema: {
        type: :object,
        properties: {
          academic_year: {
            type: :object,
            properties: {
              year: { type: :string, example: '2026/2027' },
              is_current: { type: :boolean, example: true }
            }
          }
        }
      }

      response '200', 'academic year updated' do
        let(:existing_year) { AcademicYear.create!(school: school, year: '2024/2025', is_current: false) }
        let(:id) { existing_year.id }
        let(:Authorization) { auth_token }
        let(:academic_year) do
          {
            academic_year: {
              year: '2026/2027',
              is_current: true
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
                             year: { type: :string },
                             is_current: { type: :boolean }
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
          expect(json['data']['data']['attributes']['year']).to eq('2026/2027')
          expect(json['data']['data']['attributes']['is_current']).to be true
          expect(existing_year.reload.is_current).to be true
        end
      end

      response '404', 'academic year not found' do
        let(:id) { SecureRandom.uuid }
        let(:Authorization) { auth_token }
        let(:academic_year) do
          {
            academic_year: {
              year: '2026/2027',
              is_current: false
            }
          }
        end

        run_test! do
          expect(response).to have_http_status(:not_found)
        end
      end

      response '422', 'invalid year format' do
        let(:existing_year) { AcademicYear.create!(school: school, year: '2024/2025', is_current: false) }
        let(:id) { existing_year.id }
        let(:Authorization) { auth_token }
        let(:academic_year) do
          {
            academic_year: {
              year: '2025/2028',
              is_current: false
            }
          }
        end

        run_test! do
          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)
          expect(json['success']).to be false
        end
      end
    end

    delete 'Delete academic year' do
      tags 'Management Academic Years'
      produces 'application/json'
      security [bearerAuth: []]

      response '204', 'academic year deleted' do
        let(:academic_year) { AcademicYear.create!(school: school, year: '2024/2025', is_current: false) }
        let(:id) { academic_year.id }
        let(:Authorization) { auth_token }

        run_test! do
          expect(response).to have_http_status(:no_content)
          expect(AcademicYear.find_by(id: academic_year.id)).to be_nil
        end
      end

      response '422', 'cannot delete year with classes' do
        let(:academic_year) { AcademicYear.create!(school: school, year: '2024/2025', is_current: false) }
        let(:id) { academic_year.id }
        let(:Authorization) { auth_token }

        before do
          principal
          school_manager
          academic_year
          SchoolClass.create!(
            school: school,
            name: '4A',
            year: academic_year.year,
            qr_token: SecureRandom.uuid,
            metadata: {}
          )
        end

        run_test! do
          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)
          expect(json['success']).to be false
          expect(json['errors']).to be_an(Array)
          expect(json['errors'].any? { |e| e.include?('zawiera klasy') }).to be true
          expect(AcademicYear.find_by(id: academic_year.id)).to be_present
        end
      end

      response '404', 'academic year not found' do
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
