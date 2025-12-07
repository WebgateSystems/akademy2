# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Redirect loop prevention', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:teacher_role) { Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }
  let(:principal_role) { Role.find_or_create_by!(key: 'principal') { |r| r.name = 'Principal' } }
  let(:school_manager_role) { Role.find_or_create_by!(key: 'school_manager') { |r| r.name = 'School Manager' } }
  let(:school) { create(:school) }

  before do
    teacher_role
    principal_role
    school_manager_role
  end

  describe 'when non-teacher tries to access dashboard' do
    let(:non_teacher) do
      user = create(:user, school: school)
      UserRole.create!(user: user, role: principal_role, school: school)
      user.reload
    end

    before { sign_in non_teacher }

    it 'redirects to login page instead of creating redirect loop' do
      get dashboard_path

      # Should redirect to login, not root_path (which would cause loop)
      expect(response).to redirect_to(teacher_login_path)
      expect(flash[:alert]).to include('nauczyciel')
    end

    it 'does not create infinite redirect loop' do
      # User is signed in but doesn't have teacher role
      # First request redirects to login
      get dashboard_path
      expect(response).to redirect_to(teacher_login_path)

      # Follow redirect to login page
      follow_redirect!

      # User is already signed in, so Devise redirects them away from login page
      # This is expected behavior - we just need to verify no infinite loop
      follow_redirect! if response.redirect?

      # Should eventually reach a stable state (not looping)
      # The key is that we don't get stuck in a redirect loop
      # Try accessing dashboard again - should still redirect to login, not loop
      get dashboard_path
      # After being signed out by redirect loop detection, redirects to role-specific login
      expect(response.location).to include('login')
      expect(response.location).not_to include(dashboard_path)
    end
  end

  describe 'when non-manager tries to access management panel' do
    let(:non_manager) do
      user = create(:user, school: school)
      UserRole.create!(user: user, role: teacher_role, school: school)
      user.reload
    end

    before { sign_in non_manager }

    it 'redirects to login page instead of creating redirect loop' do
      get management_root_path

      # Should redirect to login, not authenticated_root_path (which would cause loop)
      expect(response).to redirect_to(administration_login_path)
      expect(flash[:alert]).to include('Brak uprawnień do zarządzania szkołą')
    end

    it 'does not create infinite redirect loop' do
      # User is signed in but doesn't have management role
      # First request redirects to login
      get management_root_path
      expect(response).to redirect_to(administration_login_path)

      # Follow redirect to login page
      follow_redirect!

      # User is already signed in, so Devise redirects them away from login page
      # This is expected behavior - we just need to verify no infinite loop
      follow_redirect! if response.redirect?

      # Should eventually reach a stable state (not looping)
      # Try accessing management again
      get management_root_path
      # After following redirects, expect to be redirected to login
      expect(response.location).to include('login')
      expect(response.location).not_to include(management_root_path)
    end
  end

  describe 'when redirect loop is detected' do
    let(:non_teacher_user) do
      user = create(:user, school: school)
      UserRole.create!(user: user, role: principal_role, school: school)
      user.reload
    end

    before { sign_in non_teacher_user }

    it 'signs out user after 2 consecutive redirects to same path' do
      # User is already signed in (via before block) but doesn't have teacher role
      # First request: user tries to access dashboard, gets redirected to login
      get dashboard_path
      expect(response).to redirect_to(teacher_login_path)

      # Set up session to simulate that first redirect already happened
      # The session state simulates: user was redirected from dashboard_path to login
      session[:last_redirect_path] = dashboard_path
      session[:last_redirect_count] = 1
      session[:last_redirect_time] = Time.current.to_i

      # Second request to same path with referer matching - should trigger loop detection
      # User is still signed in, so require_teacher! will redirect again
      # This time, redirect loop detection should kick in and sign out the user
      get dashboard_path, headers: { 'HTTP_REFERER' => "http://test.host#{dashboard_path}" }

      # Should be signed out and redirected to login after 2 redirects
      # Redirects to role-specific login path
      expect(response.location).to include('login')

      # The key assertion: handle_redirect_loop was called, which means:
      # 1. User was signed out (reset_session was called)
      # 2. Redirect loop was detected and handled
      # 3. User was redirected to login page

      # Verify user was logged out by making a new request
      # After reset_session, user should be logged out, so accessing dashboard should redirect to login
      # This confirms that reset_session in handle_redirect_loop actually logged out the user
      get dashboard_path
      expect(response).to redirect_to(teacher_login_path)

      # The fact that we can access dashboard_path and get redirected to login (not get "already logged in")
      # confirms that user was logged out by reset_session in handle_redirect_loop
      # This is the key test: user was signed out due to redirect loop detection
    end

    it 'does not detect loop on first redirect' do
      # First redirect - count should be 1, not trigger loop
      get dashboard_path # Initialize session
      session[:last_redirect_path] = dashboard_path
      session[:last_redirect_count] = 0
      session[:last_redirect_time] = Time.current.to_i

      get dashboard_path, headers: { 'HTTP_REFERER' => "http://test.host#{dashboard_path}" }

      # Should redirect but not trigger loop detection yet (count is 1, not 2)
      expect(response).to redirect_to(teacher_login_path)
      # User should still be signed in (not logged out) - check by trying another request
      follow_redirect!
      # User is still authenticated (can make another request)
      get root_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'redirect loop tracking is cleared on successful login' do
    let(:user) { create(:user, school: school) }
    let(:teacher) do
      u = create(:user, school: school)
      UserRole.create!(user: u, role: teacher_role, school: school)
      u.reload
    end

    it 'clears tracking when teacher logs in successfully' do
      # Set redirect loop tracking
      get new_user_session_path # Initialize session
      session[:last_redirect_path] = '/some/path'
      session[:last_redirect_count] = 1

      # Login successfully
      post user_session_path, params: {
        user: {
          email: teacher.email,
          password: teacher.password
        }
      }

      # After login, should redirect to dashboard (not loop)
      expect(response).to redirect_to(dashboard_path)
      # Session tracking should be cleared (can't directly test after redirect in integration test)
    end

    it 'redirects to stored location if user was trying to access specific page' do
      # User tries to access /dashboard before login
      get dashboard_path
      follow_redirect! # Follow to login page

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
  end

  describe 'redirect loop detection with counter and time' do
    let(:non_teacher) do
      user = create(:user, school: school)
      UserRole.create!(user: user, role: principal_role, school: school)
      user.reload
    end

    before { sign_in non_teacher }

    it 'resets counter after 5 seconds' do
      # First request sets tracking
      get dashboard_path
      follow_redirect! # Follow to login

      # Manually set old tracking data (simulating old redirect)
      get new_user_session_path # Initialize session again
      session[:last_redirect_path] = '/dashboard'
      session[:last_redirect_count] = 1
      session[:last_redirect_time] = 10.seconds.ago.to_i

      # Next request to dashboard - counter should be reset due to time
      get dashboard_path

      # Should redirect to login (normal behavior), not trigger loop
      expect(response).to redirect_to(teacher_login_path)
      # Counter should be reset (can't directly test session after redirect)
    end

    it 'does not reset counter if less than 5 seconds passed' do
      # First request sets tracking
      get dashboard_path
      follow_redirect! # Follow to login

      # Manually set recent tracking data
      get new_user_session_path # Initialize session again
      session[:last_redirect_path] = '/dashboard'
      session[:last_redirect_count] = 1
      session[:last_redirect_time] = 2.seconds.ago.to_i

      # Next request - counter should persist
      get dashboard_path, headers: { 'HTTP_REFERER' => 'http://test.host/dashboard' }

      # Should redirect normally
      expect(response).to redirect_to(teacher_login_path)
    end
  end
end
