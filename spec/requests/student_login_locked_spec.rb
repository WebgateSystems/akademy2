# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Student login with locked account', type: :request do
  let(:student_role) { Role.find_or_create_by!(key: 'student', name: 'Student') }
  let(:student) do
    user = create(:user, confirmed_at: Time.current)
    user.roles << student_role
    user
  end

  describe 'POST /users/sign_in' do
    context 'when student is active' do
      it 'allows login with correct password' do
        post user_session_path, params: {
          user: { role: 'student' },
          phone: student.phone,
          password: 'Password1'
        }

        expect(response).to redirect_to(public_home_path)
      end
    end

    context 'when student is locked' do
      before do
        student.update!(locked_at: Time.current)
      end

      it 'rejects login' do
        post user_session_path, params: {
          user: { role: 'student' },
          phone: student.phone,
          password: 'Password1'
        }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'shows locked message' do
        post user_session_path, params: {
          user: { role: 'student' },
          phone: student.phone,
          password: 'Password1'
        }

        expect(response.body).to include('zablokowane')
      end
    end

    context 'when student does not exist' do
      it 'shows not found message' do
        post user_session_path, params: {
          user: { role: 'student' },
          phone: '+48999999999',
          password: 'Password1'
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('nie istnieje')
      end
    end

    context 'when password is incorrect' do
      it 'shows invalid PIN message' do
        post user_session_path, params: {
          user: { role: 'student' },
          phone: student.phone,
          password: 'WrongPassword'
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('Nieprawidłowy PIN')
      end
    end
  end
end
