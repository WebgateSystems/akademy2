# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Student Account API', type: :request do
  let!(:student_role) { Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' } }
  let!(:principal_role) { Role.find_or_create_by!(key: 'principal') { |r| r.name = 'Principal' } }
  let(:school) { create(:school) }
  let(:student) do
    user = create(:user, school: school, first_name: 'Jan', last_name: 'Kowalski',
                         confirmed_at: nil, metadata: { 'phone_verified' => false })
    UserRole.create!(user: user, role: student_role, school: school)
    user
  end
  let(:token) { Jwt::TokenService.encode({ user_id: student.id }, 1.hour.from_now) }
  let(:Authorization) { "Bearer #{token}" }

  let!(:principal) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: principal_role, school: school)
    user
  end

  path '/api/v1/student/account' do
    get 'Get account details' do
      tags 'Student Account'
      description 'Returns current student account information including verification status'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'account details' do
        schema type: :object,
               properties: {
                 success: { type: :boolean },
                 data: {
                   type: :object,
                   properties: {
                     id: { type: :string, format: :uuid },
                     full_name: { type: :string },
                     first_name: { type: :string, nullable: true },
                     last_name: { type: :string, nullable: true },
                     email: { type: :string, format: :email },
                     email_verified: { type: :boolean },
                     phone: { type: :string, nullable: true },
                     phone_verified: { type: :boolean },
                     birthdate: { type: :string, format: :date, nullable: true },
                     can_edit_email: { type: :boolean },
                     can_edit_phone: { type: :boolean }
                   }
                 }
               }

        run_test! do
          json = JSON.parse(response.body)
          expect(json['success']).to be true
          expect(json['data']['email']).to eq(student.email)
          expect(json['data']['can_edit_email']).to be true
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

    patch 'Update account' do
      tags 'Student Account'
      description 'Update email or phone if not verified'
      produces 'application/json'
      consumes 'application/json'
      security [bearerAuth: []]

      parameter name: :account, in: :body, schema: {
        type: :object,
        properties: {
          account: {
            type: :object,
            properties: {
              email: { type: :string, format: :email, description: 'New email (only if unverified)' },
              phone: { type: :string, description: 'New phone number (only if unverified)' }
            }
          }
        }
      }

      response '200', 'account updated' do
        let(:account) { { account: { email: 'newemail@example.com' } } }

        schema type: :object,
               properties: {
                 success: { type: :boolean },
                 data: {
                   type: :object,
                   properties: {
                     id: { type: :string, format: :uuid },
                     email: { type: :string },
                     can_edit_email: { type: :boolean }
                   }
                 },
                 message: { type: :string }
               }

        run_test! do
          json = JSON.parse(response.body)
          expect(json['success']).to be true
          # With skip_reconfirmation!, email should be updated directly for unverified users
          expect(json['data']['email']).to eq('newemail@example.com')
        end
      end

      response '422', 'cannot update verified email' do
        before { student.update!(confirmed_at: Time.current) }

        let(:account) { { account: { email: 'newemail@example.com' } } }

        run_test! do
          json = JSON.parse(response.body)
          expect(json['success']).to be false
          expect(json['errors']).to be_present
        end
      end

      response '401', 'unauthorized' do
        let(:Authorization) { nil }
        let(:account) { { account: { email: 'test@test.com' } } }
        run_test!
      end
    end
  end

  path '/api/v1/student/account/settings' do
    get 'Get settings' do
      tags 'Student Account'
      description 'Returns current student settings (locale, theme)'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'settings data' do
        schema type: :object,
               properties: {
                 success: { type: :boolean },
                 data: {
                   type: :object,
                   properties: {
                     locale: { type: :string },
                     theme: { type: :string },
                     available_locales: {
                       type: :array,
                       items: { type: :string }
                     },
                     available_themes: {
                       type: :array,
                       items: { type: :string }
                     }
                   }
                 }
               }

        run_test! do
          json = JSON.parse(response.body)
          expect(json['success']).to be true
          expect(json['data']['available_locales']).to include('en', 'pl')
        end
      end

      response '401', 'unauthorized' do
        let(:Authorization) { nil }
        run_test!
      end
    end

    patch 'Update settings' do
      tags 'Student Account'
      description 'Update locale, theme, and/or PIN'
      produces 'application/json'
      consumes 'application/json'
      security [bearerAuth: []]

      parameter name: :settings, in: :body, schema: {
        type: :object,
        properties: {
          settings: {
            type: :object,
            properties: {
              locale: { type: :string, enum: %w[en pl], description: 'Interface language' },
              theme: { type: :string, enum: %w[light dark], description: 'UI theme' },
              new_pin: { type: :string, pattern: '^\d{4}$', description: '4-digit PIN' },
              pin_confirmation: { type: :string, pattern: '^\d{4}$', description: 'PIN confirmation' }
            }
          }
        }
      }

      response '200', 'settings updated' do
        let(:settings) { { settings: { locale: 'pl', theme: 'dark' } } }

        schema type: :object,
               properties: {
                 success: { type: :boolean },
                 data: {
                   type: :object,
                   properties: {
                     locale: { type: :string },
                     theme: { type: :string }
                   }
                 },
                 message: { type: :string }
               }

        run_test! do
          json = JSON.parse(response.body)
          expect(json['success']).to be true
          expect(json['data']['locale']).to eq('pl')
        end
      end

      response '200', 'PIN updated' do
        let(:settings) { { settings: { new_pin: '1234', pin_confirmation: '1234' } } }

        run_test! do
          json = JSON.parse(response.body)
          expect(json['success']).to be true
          expect(student.reload.valid_password?('1234')).to be true
        end
      end

      response '422', 'PIN mismatch' do
        let(:settings) { { settings: { new_pin: '1234', pin_confirmation: '5678' } } }

        run_test! do
          json = JSON.parse(response.body)
          expect(json['success']).to be false
          expect(json['errors']).to be_present
        end
      end

      response '422', 'PIN too short' do
        let(:settings) { { settings: { new_pin: '123', pin_confirmation: '123' } } }

        run_test! do
          json = JSON.parse(response.body)
          expect(json['success']).to be false
        end
      end

      response '422', 'PIN non-numeric' do
        let(:settings) { { settings: { new_pin: 'abcd', pin_confirmation: 'abcd' } } }

        run_test! do
          json = JSON.parse(response.body)
          expect(json['success']).to be false
        end
      end

      response '401', 'unauthorized' do
        let(:Authorization) { nil }
        let(:settings) { { settings: { locale: 'en' } } }
        run_test!
      end
    end
  end

  path '/api/v1/student/account/request_deletion' do
    post 'Request account deletion' do
      tags 'Student Account'
      description 'Submit a request to delete the account. Requires school administration approval.'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'deletion requested' do
        before do
          # Ensure principal exists for notification creation
          principal
        end

        schema type: :object,
               properties: {
                 success: { type: :boolean },
                 message: { type: :string }
               }

        run_test! do
          json = JSON.parse(response.body)
          expect(json['success']).to be true

          # Verify notification was created
          notification = Notification.find_by(notification_type: 'account_deletion_request')
          expect(notification).to be_present
          expect(notification.metadata['user_id']).to eq(student.id)
        end
      end

      response '401', 'unauthorized' do
        let(:Authorization) { nil }
        run_test!
      end
    end
  end
end
