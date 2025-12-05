# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Student Quiz Results API', type: :request do
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

  let!(:subject_record) { create(:subject, school: nil, title: 'Mathematics') }
  let!(:unit) { create(:unit, subject: subject_record, title: 'Algebra') }
  let!(:learning_module) { create(:learning_module, unit: unit, title: 'Linear Equations', published: true) }

  before do
    StudentClassEnrollment.create!(student: student, school_class: school_class, status: 'approved')
  end

  path '/api/v1/student/quiz_results' do
    get 'List quiz results' do
      tags 'Student'
      description 'Returns all completed quiz results for the student'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'quiz results list' do
        let!(:existing_result) do
          create(:quiz_result, user: student, learning_module: learning_module, score: 85, passed: true)
        end

        schema type: :object,
               properties: {
                 success: { type: :boolean },
                 data: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       id: { type: :string, format: :uuid },
                       score: { type: :integer },
                       passed: { type: :boolean },
                       completed_at: { type: :string, format: :'date-time' },
                       learning_module: {
                         type: :object,
                         properties: {
                           id: { type: :string, format: :uuid },
                           title: { type: :string }
                         }
                       },
                       subject: {
                         type: :object,
                         properties: {
                           id: { type: :string, format: :uuid },
                           title: { type: :string }
                         }
                       }
                     }
                   }
                 }
               }

        run_test! do
          json = JSON.parse(response.body)
          expect(json['success']).to be true
          expect(json['data'].length).to eq(1)
        end
      end

      response '401', 'unauthorized' do
        let(:Authorization) { nil }
        run_test!
      end
    end

    post 'Submit quiz result' do
      tags 'Student'
      description 'Submit completed quiz result. Score >= 80% marks as passed.'
      produces 'application/json'
      consumes 'application/json'
      security [bearerAuth: []]

      parameter name: :params, in: :body, schema: {
        type: :object,
        properties: {
          learning_module_id: { type: :string, format: :uuid, description: 'Learning module ID' },
          score: { type: :integer, minimum: 0, maximum: 100, description: 'Quiz score percentage' },
          details: { type: :object, description: 'Additional details (answers, time spent)' }
        },
        required: %w[learning_module_id score]
      }

      response '201', 'quiz result created (passed)' do
        let(:params) do
          {
            learning_module_id: learning_module.id,
            score: 85,
            details: { answers: [1, 2, 3] }
          }
        end

        schema type: :object,
               properties: {
                 success: { type: :boolean },
                 data: {
                   type: :object,
                   properties: {
                     id: { type: :string, format: :uuid },
                     score: { type: :integer },
                     passed: { type: :boolean },
                     completed_at: { type: :string, format: :'date-time' },
                     message: { type: :string }
                   }
                 }
               }

        run_test! do
          json = JSON.parse(response.body)
          expect(json['data']['passed']).to be true
          expect(json['data']['message']).to include('Congratulations')
        end
      end

      response '201', 'quiz result created (failed)' do
        let(:failed_module) { create(:learning_module, unit: unit, title: 'Failed Module', published: true) }
        let(:params) do
          {
            learning_module_id: failed_module.id,
            score: 50
          }
        end

        run_test! do
          json = JSON.parse(response.body)
          expect(json['data']['passed']).to be false
          expect(json['data']['message']).to include('80%')
        end
      end

      response '401', 'unauthorized' do
        let(:Authorization) { nil }
        let(:params) { { learning_module_id: learning_module.id, score: 85 } }
        run_test!
      end

      response '404', 'learning module not found' do
        let(:params) { { learning_module_id: SecureRandom.uuid, score: 85 } }
        run_test!
      end
    end
  end
end
