# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TeacherRegistrationController, type: :controller do
  describe 'GET #join_school' do
    context 'with invalid token' do
      it 'redirects to root with alert' do
        get :join_school, params: { token: 'invalid-token' }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('Nieprawidłowy token szkoły')
      end
    end

    context 'with valid token' do
      let(:school) { create(:school, join_token: 'valid-token-123') }

      context 'when user is not signed in' do
        it 'stores token in session' do
          get :join_school, params: { token: school.join_token }
          expect(session[:join_school_token]).to eq(school.join_token)
          expect(session[:join_school_id]).to eq(school.id)
        end

        it 'redirects to teacher registration' do
          get :join_school, params: { token: school.join_token }
          expect(response).to redirect_to(register_teacher_path(join_token: school.join_token))
        end
      end

      context 'when user is signed in as teacher' do
        let!(:teacher_role) { Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }
        let(:teacher) do
          user = create(:user)
          UserRole.create!(user: user, role: teacher_role)
          user
        end

        before { sign_in teacher }

        context 'with approved enrollment' do
          before do
            TeacherSchoolEnrollment.create!(teacher: teacher, school: school, status: 'approved')
          end

          it 'redirects to dashboard with notice' do
            get :join_school, params: { token: school.join_token }
            expect(response).to redirect_to(dashboard_path)
            expect(flash[:notice]).to eq('Jesteś już przypisany do tej szkoły')
          end
        end

        context 'with pending enrollment' do
          before do
            TeacherSchoolEnrollment.create!(teacher: teacher, school: school, status: 'pending')
          end

          it 'redirects to dashboard with pending notice' do
            get :join_school, params: { token: school.join_token }
            expect(response).to redirect_to(dashboard_path)
            expect(flash[:notice]).to eq('Twój wniosek oczekuje na akceptację')
          end
        end

        context 'without enrollment' do
          it 'redirects to dashboard' do
            get :join_school, params: { token: school.join_token }
            expect(response).to redirect_to(dashboard_path)
            expect(flash[:notice]).to eq('Możesz teraz dołączyć do szkoły')
          end
        end
      end
    end
  end
end
