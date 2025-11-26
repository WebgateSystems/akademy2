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
