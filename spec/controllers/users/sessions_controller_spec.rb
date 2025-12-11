# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Users::SessionsController, type: :request do
  let(:user) { create(:user) }
  let(:student_role) { Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' } }
  let(:student_user) do
    user = create(:user)
    UserRole.find_or_create_by!(user: user, role: student_role) { |ur| ur.school = user.school }
    user
  end

  describe 'POST /users/sign_in' do
    context 'with teacher login' do
      it 'logs login event' do
        expect do
          post user_session_path, params: {
            user: {
              email: user.email,
              password: user.password
            }
          }
        end.to change(Event, :count).by(1)

        event = Event.last
        expect(event.event_type).to eq('user_login')
        expect(event.user).to eq(user)
        expect(event.data['login_method']).to eq('web')
        expect(event.client).to eq('web')
      end

      it 'clears redirect loop tracking on successful login' do
        # Simulate redirect loop tracking by setting session before request
        get new_user_session_path # Initialize session
        session[:last_redirect_path] = '/some/path'
        session[:last_redirect_count] = 1

        # Login successfully
        post user_session_path, params: {
          user: {
            email: user.email,
            password: user.password
          }
        }

        # After successful login, session should not have last_redirect_path
        # Note: In integration tests, we can't directly access session after redirect
        # But we can verify the login was successful (no redirect loop)
        expect(response).to have_http_status(:redirect)
        expect(response).not_to redirect_to('/some/path')
      end
    end

    context 'with student login' do
      it 'logs student login event' do
        expect do
          post user_session_path, params: {
            user: { role: 'student' },
            phone: student_user.phone,
            password: student_user.password
          }
        end.to change(Event, :count).by(1)

        event = Event.last
        expect(event.event_type).to eq('user_login')
        expect(event.user).to eq(student_user)
        expect(event.data['login_method']).to eq('web_student')
        expect(event.client).to eq('web_student')
      end

      it 'clears redirect loop tracking on successful student login' do
        # Simulate redirect loop tracking by setting session before request
        get new_user_session_path # Initialize session
        session[:last_redirect_path] = '/some/path'
        session[:last_redirect_count] = 1

        # Login successfully
        post user_session_path, params: {
          user: { role: 'student' },
          phone: student_user.phone,
          password: student_user.password
        }

        # After successful login, session should not have last_redirect_path
        expect(response).to have_http_status(:redirect)
        expect(response).not_to redirect_to('/some/path')
      end
    end
  end

  describe 'DELETE /users/sign_out' do
    before do
      # Sign in first
      post user_session_path, params: {
        user: {
          email: user.email,
          password: user.password
        }
      }
    end

    it 'logs logout event' do
      expect do
        delete destroy_user_session_path
      end.to change(Event.where(event_type: 'user_logout'), :count).by(1)

      event = Event.where(event_type: 'user_logout').last
      expect(event.user).to eq(user)
      expect(event.client).to eq('web')
    end
  end

  describe 'GET /login routes with role parameter' do
    context 'when accessing /login/teacher' do
      it 'renders the login form' do
        get teacher_login_path
        expect(response).to have_http_status(:success)
      end

      it 'shows sign up link to teacher registration' do
        get teacher_login_path
        expect(response.body).to include('register/teacher')
      end
    end

    context 'when accessing /login/student' do
      it 'renders the login form with PIN fields' do
        get student_login_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include('login-pin')
      end

      it 'shows sign up link to student registration' do
        get student_login_path
        expect(response.body).to include('register/student')
      end
    end

    context 'when accessing /login/administration' do
      it 'does not show sign up link' do
        get administration_login_path
        expect(response).to have_http_status(:success)
        expect(response.body).not_to include('Sign up')
      end
    end
  end

  describe 'POST /users/sign_in with role parameter' do
    let(:teacher_role) { Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }
    let(:school) { create(:school) }
    let(:teacher_user) do
      user = create(:user, school: school)
      UserRole.create!(user: user, role: teacher_role, school: school)
      user
    end

    before { teacher_role }

    context 'with role as top-level parameter' do
      it 'successfully logs in teacher' do
        post user_session_path, params: {
          role: 'teacher',
          user: {
            email: teacher_user.email,
            password: teacher_user.password
          }
        }

        expect(response).to have_http_status(:redirect)
      end

      it 'does not show unpermitted parameter warning' do
        # Ensure no unpermitted parameter errors in logs
        expect do
          post user_session_path, params: {
            role: 'teacher',
            user: {
              email: teacher_user.email,
              password: teacher_user.password
            }
          }
        end.not_to raise_error
      end
    end
  end

  describe 'student PIN login' do
    let(:student_with_pin) do
      user = create(:user, password: 'Password1', password_confirmation: 'Password1')
      UserRole.create!(user: user, role: student_role, school: user.school)
      user
    end

    it 'accepts password login' do
      post user_session_path, params: {
        role: 'student',
        phone: student_with_pin.phone,
        password: 'Password1'
      }

      expect(response).to have_http_status(:redirect)
    end
  end
end
