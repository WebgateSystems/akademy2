# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'After sign in redirects', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:teacher_role) { Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }
  let(:student_role) { Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' } }
  let(:principal_role) { Role.find_or_create_by!(key: 'principal') { |r| r.name = 'Principal' } }
  let(:school_manager_role) { Role.find_or_create_by!(key: 'school_manager') { |r| r.name = 'School Manager' } }
  let(:admin_role) { Role.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' } }
  let(:school) { create(:school) }

  before do
    teacher_role
    student_role
    principal_role
    school_manager_role
    admin_role
  end

  describe 'redirects to stored location when user tries to access specific page' do
    let(:teacher) do
      u = create(:user, school: school)
      UserRole.create!(user: u, role: teacher_role, school: school)
      u.reload
    end

    it 'redirects teacher to /dashboard after login when trying to access /dashboard' do
      # Try to access dashboard without login
      get dashboard_path
      expect(response).to redirect_to(new_user_session_path)

      # Login
      post user_session_path, params: {
        user: {
          email: teacher.email,
          password: teacher.password
        }
      }

      # Should redirect back to /dashboard (stored location)
      expect(response).to redirect_to(dashboard_path)
    end

    it 'rejects teacher trying to access /management (no permissions)' do
      # Teacher doesn't have management permissions
      # Try to access management without login
      get management_root_path
      expect(response).to redirect_to(new_user_session_path)

      # Login as teacher (who has no management access)
      post user_session_path, params: {
        user: {
          email: teacher.email,
          password: teacher.password
        }
      }

      # Should be rejected with 422 (no permissions for this path)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'redirects principal to /management after login when trying to access /management' do
      principal = create(:user, school: school)
      UserRole.create!(user: principal, role: principal_role, school: school)

      # Try to access management without login
      get management_root_path
      expect(response).to redirect_to(new_user_session_path)

      # Login as principal (who has management access)
      post user_session_path, params: {
        user: {
          email: principal.email,
          password: principal.password
        }
      }

      # Should redirect back to /management (stored location)
      expect(response).to redirect_to(management_root_path)
    end
  end

  describe 'redirects based on roles when no stored location' do
    context 'when user is teacher' do
      let(:teacher) do
        u = create(:user, school: school)
        UserRole.create!(user: u, role: teacher_role, school: school)
        u.reload
      end

      it 'redirects to dashboard_path' do
        post user_session_path, params: {
          user: {
            email: teacher.email,
            password: teacher.password
          }
        }

        expect(response).to redirect_to(dashboard_path)
      end
    end

    context 'when user is student' do
      let(:student) do
        u = create(:user, school: school)
        UserRole.create!(user: u, role: student_role, school: school)
        u.reload
      end

      it 'redirects to public_home_path' do
        post user_session_path, params: {
          user: {
            email: student.email,
            password: student.password
          }
        }

        expect(response).to redirect_to(public_home_path)
      end
    end

    context 'when user is principal (without teacher role)' do
      let(:principal) do
        u = create(:user, school: school)
        UserRole.create!(user: u, role: principal_role, school: school)
        u.reload
      end

      it 'redirects to management_root_path' do
        post user_session_path, params: {
          user: {
            email: principal.email,
            password: principal.password
          }
        }

        expect(response).to redirect_to(management_root_path)
      end
    end

    context 'when user is school_manager (without teacher role)' do
      let(:manager) do
        u = create(:user, school: school)
        UserRole.create!(user: u, role: school_manager_role, school: school)
        u.reload
      end

      it 'redirects to management_root_path' do
        post user_session_path, params: {
          user: {
            email: manager.email,
            password: manager.password
          }
        }

        expect(response).to redirect_to(management_root_path)
      end
    end

    context 'when user is admin' do
      let(:admin) do
        u = create(:user, school: school)
        UserRole.create!(user: u, role: admin_role, school: school)
        u.reload
      end

      it 'redirects to admin_root_path' do
        # Admin uses different login endpoint
        result = double('SessionResult', success?: true, form: admin, access_token: 'token')
        allow(Api::V1::Sessions::CreateSession).to receive(:call).and_return(result)

        post admin_session_path, params: {
          user: {
            email: admin.email,
            password: admin.password
          }
        }

        expect(response).to redirect_to(admin_root_path)
      end
    end
  end

  describe 'root path always shows landing page' do
    let(:teacher) do
      u = create(:user, school: school)
      UserRole.create!(user: u, role: teacher_role, school: school)
      u.reload
    end

    it 'shows landing page for unauthenticated users' do
      get root_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('home')
    end

    it 'shows landing page for authenticated teachers' do
      sign_in teacher
      get root_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('home')
    end
  end
end
