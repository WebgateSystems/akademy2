# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Student Dashboard API', type: :request do
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

  let!(:subject_record) { create(:subject, school: nil, title: 'Mathematics', order_index: 1) }
  let!(:unit) { create(:unit, subject: subject_record, title: 'Algebra', order_index: 1) }
  let!(:learning_module) do
    create(:learning_module, unit: unit, title: 'Linear Equations', order_index: 1, published: true)
  end

  before do
    StudentClassEnrollment.create!(student: student, school_class: school_class, status: 'approved')
    # Create contents for learning module
    create(:content, learning_module: learning_module, title: 'Introduction Video',
                     content_type: 'video', order_index: 1)
    create(:content, learning_module: learning_module, title: 'Quiz',
                     content_type: 'quiz', order_index: 2,
                     payload: { 'questions' => [{ 'question' => 'What is 2+2?', 'answers' => %w[3 4 5] }] })
  end

  path '/api/v1/student/dashboard' do
    get 'Get student dashboard' do
      tags 'Student'
      description 'Returns student dashboard with subjects and progress'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'dashboard data' do
        schema type: :object,
               properties: {
                 success: { type: :boolean },
                 data: {
                   type: :object,
                   properties: {
                     student: {
                       type: :object,
                       properties: {
                         id: { type: :string, format: :uuid },
                         first_name: { type: :string },
                         last_name: { type: :string },
                         email: { type: :string, format: :email }
                       }
                     },
                     school: {
                       type: :object,
                       nullable: true,
                       properties: {
                         id: { type: :string, format: :uuid },
                         name: { type: :string },
                         logo_url: { type: :string, nullable: true }
                       }
                     },
                     classes: {
                       type: :array,
                       items: {
                         type: :object,
                         properties: {
                           id: { type: :string, format: :uuid },
                           name: { type: :string },
                           year: { type: :string }
                         }
                       }
                     },
                     subjects: {
                       type: :array,
                       items: {
                         type: :object,
                         properties: {
                           id: { type: :string, format: :uuid },
                           title: { type: :string },
                           slug: { type: :string },
                           icon_url: { type: :string, nullable: true },
                           color_light: { type: :string, nullable: true },
                           color_dark: { type: :string, nullable: true },
                           total_modules: { type: :integer },
                           completed_modules: { type: :integer },
                           completion_rate: { type: :integer },
                           average_score: { type: :integer }
                         }
                       }
                     }
                   }
                 }
               }

        run_test! do
          json = JSON.parse(response.body)
          expect(json['success']).to be true
          expect(json['data']['student']['email']).to eq(student.email)
        end
      end

      response '401', 'unauthorized' do
        let(:Authorization) { nil }
        run_test!
      end

      response '403', 'student access required' do
        let(:teacher_role) { Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }
        let(:teacher) do
          user = create(:user, school: school)
          UserRole.create!(user: user, role: teacher_role, school: school)
          user
        end
        let(:Authorization) { "Bearer #{Jwt::TokenService.encode({ user_id: teacher.id }, 1.hour.from_now)}" }
        run_test!
      end
    end
  end

  path '/api/v1/student/subjects/{id}' do
    parameter name: :id, in: :path, type: :string, format: :uuid, description: 'Subject ID'

    get 'Get subject details' do
      tags 'Student'
      description 'Returns subject with units, modules and progress'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'subject details' do
        let(:id) { subject_record.id }

        schema type: :object,
               properties: {
                 success: { type: :boolean },
                 data: {
                   type: :object,
                   properties: {
                     subject: {
                       type: :object,
                       properties: {
                         id: { type: :string, format: :uuid },
                         title: { type: :string },
                         slug: { type: :string },
                         icon_url: { type: :string, nullable: true },
                         color_light: { type: :string, nullable: true },
                         color_dark: { type: :string, nullable: true }
                       }
                     },
                     units: {
                       type: :array,
                       items: {
                         type: :object,
                         properties: {
                           id: { type: :string, format: :uuid },
                           title: { type: :string },
                           order_index: { type: :integer },
                           modules: {
                             type: :array,
                             items: {
                               type: :object,
                               properties: {
                                 id: { type: :string, format: :uuid },
                                 title: { type: :string },
                                 order_index: { type: :integer },
                                 contents_count: { type: :integer },
                                 completed: { type: :boolean },
                                 score: { type: :integer, nullable: true }
                               }
                             }
                           }
                         }
                       }
                     },
                     progress: {
                       type: :object,
                       properties: {
                         total_modules: { type: :integer },
                         completed_modules: { type: :integer },
                         average_score: { type: :integer }
                       }
                     }
                   }
                 }
               }

        run_test! do
          json = JSON.parse(response.body)
          expect(json['data']['subject']['title']).to eq('Mathematics')
        end
      end

      response '401', 'unauthorized' do
        let(:id) { subject_record.id }
        let(:Authorization) { nil }
        run_test!
      end

      response '404', 'subject not found' do
        let(:id) { SecureRandom.uuid }
        run_test!
      end
    end
  end

  path '/api/v1/student/learning_modules/{id}' do
    parameter name: :id, in: :path, type: :string, format: :uuid, description: 'Learning module ID'

    get 'Get learning module with contents' do
      tags 'Student'
      description 'Returns module with video, infographic and quiz for learning flow'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'module details' do
        let(:id) { learning_module.id }

        schema type: :object,
               properties: {
                 success: { type: :boolean },
                 data: {
                   type: :object,
                   properties: {
                     module: {
                       type: :object,
                       properties: {
                         id: { type: :string, format: :uuid },
                         title: { type: :string },
                         unit_id: { type: :string, format: :uuid },
                         unit_title: { type: :string },
                         single_flow: { type: :boolean }
                       }
                     },
                     contents: {
                       type: :array,
                       items: {
                         type: :object,
                         properties: {
                           id: { type: :string, format: :uuid },
                           title: { type: :string },
                           content_type: { type: :string },
                           order_index: { type: :integer },
                           file_url: { type: :string, nullable: true },
                           poster_url: { type: :string, nullable: true },
                           subtitles_url: { type: :string, nullable: true },
                           youtube_url: { type: :string, nullable: true },
                           duration_sec: { type: :integer, nullable: true },
                           payload: { type: :object, nullable: true }
                         }
                       }
                     },
                     quiz: {
                       type: :object,
                       nullable: true,
                       properties: {
                         id: { type: :string, format: :uuid },
                         title: { type: :string },
                         questions: { type: :array },
                         pass_threshold: { type: :integer }
                       }
                     },
                     previous_result: {
                       type: :object,
                       nullable: true,
                       properties: {
                         id: { type: :string, format: :uuid },
                         score: { type: :integer },
                         passed: { type: :boolean },
                         completed_at: { type: :string, format: :'date-time' },
                         details: { type: :object }
                       }
                     }
                   }
                 }
               }

        run_test! do
          json = JSON.parse(response.body)
          expect(json['data']['module']['title']).to eq('Linear Equations')
          expect(json['data']['quiz']).not_to be_nil
        end
      end

      response '401', 'unauthorized' do
        let(:id) { learning_module.id }
        let(:Authorization) { nil }
        run_test!
      end

      response '404', 'module not found' do
        let(:id) { SecureRandom.uuid }
        run_test!
      end
    end
  end
end
