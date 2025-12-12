# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'User Registration API', type: :request do
  let!(:student_role) { Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' } }
  let!(:teacher_role) { Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }

  let(:school) { create(:school) }
  let(:academic_year) { school.academic_years.create!(year: '2024/2025', is_current: true, started_at: Date.current) }
  let(:school_class) do
    SchoolClass.create!(name: '1A', school: school, year: academic_year.year, qr_token: SecureRandom.uuid)
  end

  before do
    academic_year
    school_class
  end

  path '/api/v1/register/student' do
    post 'Register a new student' do
      tags 'Registration'
      consumes 'application/json'
      produces 'application/json'
      security [] # No authentication required

      parameter name: :params, in: :body, required: true, schema: {
        type: :object,
        required: %w[user],
        properties: {
          user: {
            type: :object,
            required: %w[email password password_confirmation first_name last_name phone],
            properties: {
              email: { type: :string, format: :email, description: 'Student email address' },
              password: { type: :string, description: 'PIN (4 digits)' },
              password_confirmation: { type: :string, description: 'PIN confirmation' },
              first_name: { type: :string, description: 'First name' },
              last_name: { type: :string, description: 'Last name' },
              phone: { type: :string, description: 'Phone number (format: +48123456789)' },
              locale: { type: :string, enum: %w[en pl], description: 'Preferred locale (optional)' }
            }
          },
          class_token: { type: :string, description: 'Class join token (optional)' },
          join_token: { type: :string, description: 'Join token alias (optional)' }
        }
      }

      response '201', 'student registered successfully' do
        description 'Student registered without class'

        let(:params) do
          {
            user: {
              email: "student_#{SecureRandom.hex(4)}@example.com",
              password: '1234',
              password_confirmation: '1234',
              first_name: 'Jan',
              last_name: 'Kowalski',
              phone: '+48123456789',
              locale: 'pl'
            }
          }
        end

        schema type: :object,
               properties: {
                 user_id: { type: :string, format: :uuid },
                 email: { type: :string },
                 role: { type: :string, enum: ['student'] },
                 status: { type: :string, enum: ['pending_approval'] },
                 school_id: { type: :string, format: :uuid, nullable: true },
                 access_token: { type: :string }
               },
               required: %w[user_id email role status access_token]

        run_test! do
          json = JSON.parse(response.body)
          expect(json['user_id']).to be_present
          expect(json['role']).to eq('student')
          expect(json['school_id']).to be_nil

          created_user = User.find(json['user_id'])
          expect(created_user.roles.map(&:key)).to include('student')
        end
      end

      response '201', 'student registered with class token' do
        description 'Student registered and enrolled in a class'

        let(:params) do
          {
            user: {
              email: "student_#{SecureRandom.hex(4)}@example.com",
              password: '1234',
              password_confirmation: '1234',
              first_name: 'Anna',
              last_name: 'Nowak',
              phone: '+48987654321',
              locale: 'pl'
            },
            class_token: school_class.join_token
          }
        end

        run_test! do
          json = JSON.parse(response.body)
          expect(json['user_id']).to be_present
          expect(json['role']).to eq('student')
          expect(json['school_id']).to eq(school.id)

          created_user = User.find(json['user_id'])
          expect(created_user.school).to eq(school)
          expect(created_user.student_class_enrollments.exists?(school_class: school_class)).to be true
        end
      end

      response '422', 'validation errors' do
        description 'Invalid user data'

        let(:params) do
          {
            user: {
              email: 'invalid-email',
              password: '123',
              password_confirmation: '456',
              first_name: '',
              last_name: '',
              phone: ''
            }
          }
        end

        schema type: :object,
               properties: {
                 errors: { type: :array, items: { type: :string } }
               },
               required: ['errors']

        run_test! do
          json = JSON.parse(response.body)
          expect(json['errors']).to be_present
        end
      end
    end
  end

  path '/api/v1/register/teacher' do
    post 'Register a new teacher' do
      tags 'Registration'
      consumes 'application/json'
      produces 'application/json'
      security [] # No authentication required

      parameter name: :params, in: :body, required: true, schema: {
        type: :object,
        required: %w[user],
        properties: {
          user: {
            type: :object,
            required: %w[email password password_confirmation first_name last_name phone],
            properties: {
              email: { type: :string, format: :email, description: 'Teacher email address' },
              password: { type: :string, description: 'Password (min 8 characters)' },
              password_confirmation: { type: :string, description: 'Password confirmation' },
              first_name: { type: :string, description: 'First name' },
              last_name: { type: :string, description: 'Last name' },
              phone: { type: :string, description: 'Phone number (format: +48123456789)' },
              locale: { type: :string, enum: %w[en pl], description: 'Preferred locale (optional)' }
            }
          },
          school_token: { type: :string, description: 'School join token (optional)' },
          join_token: { type: :string, description: 'Join token alias (optional)' }
        }
      }

      response '201', 'teacher registered successfully' do
        description 'Teacher registered without school'

        let(:params) do
          {
            user: {
              email: "teacher_#{SecureRandom.hex(4)}@example.com",
              password: 'password123',
              password_confirmation: 'password123',
              first_name: 'Maria',
              last_name: 'Wiśniewska',
              phone: '+48111222333',
              locale: 'pl'
            }
          }
        end

        schema type: :object,
               properties: {
                 user_id: { type: :string, format: :uuid },
                 email: { type: :string },
                 role: { type: :string, enum: ['teacher'] },
                 status: { type: :string, enum: ['pending_approval'] },
                 school_id: { type: :string, format: :uuid, nullable: true },
                 access_token: { type: :string }
               },
               required: %w[user_id email role status access_token]

        run_test! do
          json = JSON.parse(response.body)
          expect(json['user_id']).to be_present
          expect(json['role']).to eq('teacher')
          expect(json['school_id']).to be_nil

          created_user = User.find(json['user_id'])
          expect(created_user.roles.map(&:key)).to include('teacher')
        end
      end

      response '201', 'teacher registered with school token' do
        description 'Teacher registered and enrolled in a school'

        let(:params) do
          {
            user: {
              email: "teacher_#{SecureRandom.hex(4)}@example.com",
              password: 'password123',
              password_confirmation: 'password123',
              first_name: 'Piotr',
              last_name: 'Zieliński',
              phone: '+48444555666',
              locale: 'pl'
            },
            school_token: school.join_token
          }
        end

        run_test! do
          json = JSON.parse(response.body)
          expect(json['user_id']).to be_present
          expect(json['role']).to eq('teacher')
          expect(json['school_id']).to eq(school.id)

          created_user = User.find(json['user_id'])
          expect(created_user.school).to eq(school)
          expect(created_user.teacher_school_enrollments.exists?(school: school, status: 'pending')).to be true
        end
      end

      response '422', 'validation errors' do
        description 'Invalid user data'

        let(:params) do
          {
            user: {
              email: 'invalid-email',
              password: 'short',
              password_confirmation: 'different',
              first_name: '',
              last_name: '',
              phone: ''
            }
          }
        end

        schema type: :object,
               properties: {
                 errors: { type: :array, items: { type: :string } }
               },
               required: ['errors']

        run_test! do
          json = JSON.parse(response.body)
          expect(json['errors']).to be_present
        end
      end
    end
  end
end
