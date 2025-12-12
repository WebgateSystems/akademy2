# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Student Videos API', type: :request do
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

  let!(:subject_record) { create(:subject, school: school, title: 'Mathematics', order_index: 1) }

  before do
    StudentClassEnrollment.create!(student: student, school_class: school_class, status: 'approved')
  end

  path '/api/v1/student/videos' do
    get 'List videos' do
      tags 'Student'
      description 'List all approved videos with optional filtering by subject and search'
      produces 'application/json'
      security [bearerAuth: []]

      parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number'
      parameter name: :per_page, in: :query, type: :integer, required: false, description: 'Items per page'
      parameter name: :q, in: :query, type: :string, required: false, description: 'Search query'
      parameter name: :subject_id, in: :query, type: :string, format: :uuid, required: false,
                description: 'Filter by subject ID'

      response '200', 'videos list' do
        let!(:approved_video) do
          other_student = create(:user, school: school)
          UserRole.create!(user: other_student, role: student_role, school: school)
          create(:student_video,
                 user: other_student,
                 school: school,
                 subject: subject_record,
                 title: 'Math Tutorial',
                 description: 'Learn mathematics',
                 status: 'approved')
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
                       title: { type: :string },
                       description: { type: :string, nullable: true },
                       file_url: { type: :string, nullable: true },
                       thumbnail_url: { type: :string, nullable: true },
                       youtube_url: { type: :string, nullable: true },
                       duration_sec: { type: :integer, nullable: true },
                       likes_count: { type: :integer },
                       liked_by_me: { type: :boolean },
                       author: {
                         type: :object,
                         properties: {
                           id: { type: :string, format: :uuid },
                           name: { type: :string },
                           is_me: { type: :boolean }
                         }
                       },
                       subject: {
                         type: :object,
                         properties: {
                           id: { type: :string, format: :uuid },
                           title: { type: :string }
                         }
                       },
                       school: {
                         type: :object,
                         nullable: true,
                         properties: {
                           id: { type: :string, format: :uuid },
                           name: { type: :string }
                         }
                       },
                       created_at: { type: :string, format: :'date-time' },
                       can_delete: { type: :boolean }
                     }
                   }
                 },
                 meta: {
                   type: :object,
                   properties: {
                     page: { type: :integer },
                     per_page: { type: :integer },
                     total: { type: :integer },
                     total_pages: { type: :integer }
                   }
                 }
               }

        run_test! do
          json = JSON.parse(response.body)
          expect(json['success']).to be true
          expect(json['data']).to be_an(Array)
        end
      end

      response '200', 'videos list with search query', document: false do
        let!(:video1) do
          other_student = create(:user, school: school)
          UserRole.create!(user: other_student, role: student_role, school: school)
          create(:student_video, user: other_student, school: school, subject: subject_record,
                                 title: 'Math Tutorial', status: 'approved')
        end
        let!(:video2) do
          other_student = create(:user, school: school)
          UserRole.create!(user: other_student, role: student_role, school: school)
          create(:student_video, user: other_student, school: school, subject: subject_record,
                                 title: 'Science Lesson', status: 'approved')
        end
        let(:q) { 'Math' }

        run_test! do
          json = JSON.parse(response.body)
          expect(json['success']).to be true
          expect(json['data'].length).to eq(1)
          expect(json['data'].first['title']).to eq('Math Tutorial')
        end
      end

      response '401', 'unauthorized' do
        let(:Authorization) { nil }
        run_test!
      end
    end

    post 'Upload video' do
      tags 'Student'
      description 'Upload a new video. Video will be pending until teacher approval.'
      produces 'application/json'
      consumes 'multipart/form-data'
      security [bearerAuth: []]

      parameter name: :video, in: :formData, schema: {
        type: :object,
        properties: {
          title: { type: :string, description: 'Video title' },
          description: { type: :string, description: 'Video description' },
          subject_id: { type: :string, format: :uuid, description: 'Subject ID' },
          file: { type: :string, format: :binary, description: 'Video file' }
        },
        required: %w[title subject_id file]
      }

      response '201', 'video uploaded' do
        let(:video) do
          {
            title: 'My Math Video',
            description: 'A tutorial about algebra',
            subject_id: subject_record.id,
            file: Rack::Test::UploadedFile.new(
              Rails.root.join('spec/fixtures/test.mp4'),
              'video/mp4'
            )
          }
        end

        schema type: :object,
               properties: {
                 success: { type: :boolean },
                 data: {
                   type: :object,
                   properties: {
                     id: { type: :string, format: :uuid },
                     title: { type: :string },
                     description: { type: :string, nullable: true },
                     status: { type: :string },
                     subject: {
                       type: :object,
                       properties: {
                         id: { type: :string, format: :uuid },
                         title: { type: :string }
                       }
                     }
                   }
                 },
                 message: { type: :string }
               }

        run_test! do
          json = JSON.parse(response.body)
          expect(json['success']).to be true
          expect(json['data']['status']).to eq('pending')
          expect(json['data']['title']).to eq('My Math Video')
        end
      end

      response '401', 'unauthorized' do
        let(:Authorization) { nil }
        let(:video) { { title: 'Test', subject_id: subject_record.id } }
        run_test!
      end

      response '422', 'validation error' do
        let(:video) { { title: '', subject_id: subject_record.id } }
        run_test!
      end
    end
  end

  path '/api/v1/student/videos/my' do
    get 'List my videos' do
      tags 'Student'
      description 'List all videos uploaded by current student (all statuses)'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'my videos list' do
        let!(:my_pending_video) do
          create(:student_video,
                 user: student,
                 school: school,
                 subject: subject_record,
                 title: 'My Pending Video',
                 status: 'pending')
        end

        let!(:my_approved_video) do
          create(:student_video,
                 user: student,
                 school: school,
                 subject: subject_record,
                 title: 'My Approved Video',
                 status: 'approved')
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
                       title: { type: :string },
                       status: { type: :string },
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
          expect(json['data'].length).to eq(2)
          expect(json['data'].map { |v| v['status'] }).to contain_exactly('pending', 'approved')
        end
      end

      response '401', 'unauthorized' do
        let(:Authorization) { nil }
        run_test!
      end
    end
  end

  path '/api/v1/student/videos/{id}' do
    parameter name: :id, in: :path, type: :string, format: :uuid, description: 'Video ID'

    get 'Get video details' do
      tags 'Student'
      description 'Get video details by ID'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'video details' do
        let!(:video) do
          create(:student_video,
                 user: student,
                 school: school,
                 subject: subject_record,
                 title: 'My Video',
                 description: 'Video description',
                 status: 'approved')
        end
        let(:id) { video.id }

        schema type: :object,
               properties: {
                 success: { type: :boolean },
                 data: {
                   type: :object,
                   properties: {
                     id: { type: :string, format: :uuid },
                     title: { type: :string },
                     description: { type: :string, nullable: true },
                     status: { type: :string },
                     author: {
                       type: :object,
                       properties: {
                         id: { type: :string, format: :uuid },
                         name: { type: :string },
                         is_me: { type: :boolean }
                       }
                     }
                   }
                 }
               }

        run_test! do
          json = JSON.parse(response.body)
          expect(json['success']).to be true
          expect(json['data']['id']).to eq(video.id.to_s)
          expect(json['data']['author']['is_me']).to be true
        end
      end

      response '401', 'unauthorized' do
        let(:id) { SecureRandom.uuid }
        let(:Authorization) { nil }
        run_test!
      end

      response '404', 'video not found' do
        let(:id) { SecureRandom.uuid }
        run_test!
      end
    end

    patch 'Update video' do
      tags 'Student'
      description 'Update own pending video (title and description only). Cannot update approved or rejected videos.'
      produces 'application/json'
      consumes 'application/json'
      security [bearerAuth: []]

      parameter name: :video, in: :body, schema: {
        type: :object,
        properties: {
          video: {
            type: :object,
            properties: {
              title: { type: :string, description: 'Video title' },
              description: { type: :string, description: 'Video description' }
            },
            required: ['title']
          }
        },
        required: ['video']
      }

      response '200', 'video updated' do
        let!(:pending_video) do
          create(:student_video,
                 user: student,
                 school: school,
                 subject: subject_record,
                 title: 'Old Title',
                 description: 'Old description',
                 status: 'pending')
        end
        let(:id) { pending_video.id }
        let(:video) { { video: { title: 'New Title', description: 'New description' } } }

        schema type: :object,
               properties: {
                 success: { type: :boolean },
                 data: {
                   type: :object,
                   properties: {
                     id: { type: :string, format: :uuid },
                     title: { type: :string },
                     description: { type: :string, nullable: true },
                     status: { type: :string }
                   }
                 },
                 message: { type: :string }
               }

        run_test! do
          json = JSON.parse(response.body)
          expect(json['success']).to be true
          expect(json['data']['title']).to eq('New Title')
          expect(json['data']['description']).to eq('New description')
          expect(json['data']['status']).to eq('pending')
        end
      end

      response '401', 'unauthorized' do
        let(:id) { SecureRandom.uuid }
        let(:Authorization) { nil }
        let(:video) { { video: { title: 'Test' } } }
        run_test!
      end

      response '403', 'forbidden - not own video' do
        let(:other_student) do
          user = create(:user, school: school)
          UserRole.create!(user: user, role: student_role, school: school)
          user
        end
        let!(:other_video) do
          create(:student_video,
                 user: other_student,
                 school: school,
                 subject: subject_record,
                 title: 'Other Video',
                 status: 'pending')
        end
        let(:id) { other_video.id }
        let(:video) { { video: { title: 'Hacked Title' } } }

        run_test! do
          json = JSON.parse(response.body)
          expect(json['success']).to be false
          expect(json['error']).to include('own videos')
        end
      end

      response '422', 'cannot update approved video' do
        let!(:approved_video) do
          create(:student_video,
                 user: student,
                 school: school,
                 subject: subject_record,
                 title: 'Approved Video',
                 status: 'approved')
        end
        let(:id) { approved_video.id }
        let(:video) { { video: { title: 'New Title' } } }

        run_test! do
          json = JSON.parse(response.body)
          expect(json['success']).to be false
          expect(json['error']).to include('pending')
        end
      end

      response '404', 'video not found' do
        let(:id) { SecureRandom.uuid }
        let(:video) { { video: { title: 'Test' } } }
        run_test!
      end
    end

    delete 'Delete video' do
      tags 'Student'
      description 'Delete own pending video. Cannot delete approved or rejected videos.'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'video deleted' do
        let!(:pending_video) do
          create(:student_video,
                 user: student,
                 school: school,
                 subject: subject_record,
                 title: 'To Delete',
                 status: 'pending')
        end
        let(:id) { pending_video.id }

        schema type: :object,
               properties: {
                 success: { type: :boolean },
                 message: { type: :string }
               }

        run_test! do
          json = JSON.parse(response.body)
          expect(json['success']).to be true
          expect(StudentVideo.find_by(id: pending_video.id)).to be_nil
        end
      end

      response '401', 'unauthorized' do
        let(:id) { SecureRandom.uuid }
        let(:Authorization) { nil }
        run_test!
      end

      response '403', 'forbidden - not own video' do
        let(:other_student) do
          user = create(:user, school: school)
          UserRole.create!(user: user, role: student_role, school: school)
          user
        end
        let!(:other_video) do
          create(:student_video,
                 user: other_student,
                 school: school,
                 subject: subject_record,
                 title: 'Other Video',
                 status: 'pending')
        end
        let(:id) { other_video.id }

        run_test! do
          json = JSON.parse(response.body)
          expect(json['success']).to be false
        end
      end

      response '404', 'video not found' do
        let(:id) { SecureRandom.uuid }
        run_test!
      end
    end
  end

  path '/api/v1/student/videos/{id}/like' do
    parameter name: :id, in: :path, type: :string, format: :uuid, description: 'Video ID'

    post 'Toggle like on video' do
      tags 'Student'
      description 'Like or unlike a video'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'like toggled' do
        let!(:video) do
          create(:student_video,
                 user: student,
                 school: school,
                 subject: subject_record,
                 title: 'Video to Like',
                 status: 'approved')
        end
        let(:id) { video.id }

        schema type: :object,
               properties: {
                 success: { type: :boolean },
                 data: {
                   type: :object,
                   properties: {
                     liked: { type: :boolean },
                     likes_count: { type: :integer }
                   }
                 }
               }

        run_test! do
          json = JSON.parse(response.body)
          expect(json['success']).to be true
          expect(json['data']).to have_key('liked')
          expect(json['data']).to have_key('likes_count')
        end
      end

      response '401', 'unauthorized' do
        let(:id) { SecureRandom.uuid }
        let(:Authorization) { nil }
        run_test!
      end

      response '404', 'video not found' do
        let(:id) { SecureRandom.uuid }
        run_test!
      end
    end
  end

  path '/api/v1/student/videos/subjects' do
    get 'Get subjects for filtering' do
      tags 'Student'
      description 'Get list of subjects available for video filtering'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'subjects list' do
        schema type: :object,
               properties: {
                 success: { type: :boolean },
                 data: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       id: { type: :string, format: :uuid },
                       title: { type: :string },
                       slug: { type: :string }
                     }
                   }
                 }
               }

        run_test! do
          json = JSON.parse(response.body)
          expect(json['success']).to be true
          expect(json['data']).to be_an(Array)
        end
      end

      response '401', 'unauthorized' do
        let(:Authorization) { nil }
        run_test!
      end
    end
  end
end
