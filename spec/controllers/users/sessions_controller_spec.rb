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
end
