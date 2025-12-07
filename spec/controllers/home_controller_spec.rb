# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HomeController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:student_role) { Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' } }
  let(:teacher_role) { Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }
  let(:school) { create(:school) }

  before do
    student_role
    teacher_role
  end

  describe 'GET /' do
    context 'when user is not signed in' do
      it 'renders landing page' do
        get root_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include('AKAdemy')
      end
    end

    context 'when user is signed in as student' do
      let(:student) do
        user = create(:user, school: school)
        UserRole.create!(user: user, role: student_role, school: school)
        user.reload
      end

      before { sign_in student }

      it 'renders landing page (root is always landing)' do
        get root_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include('AKAdemy')
      end
    end

    context 'when user is signed in as teacher' do
      let(:teacher) do
        user = create(:user, school: school)
        UserRole.create!(user: user, role: teacher_role, school: school)
        user.reload
      end

      before { sign_in teacher }

      it 'renders landing page' do
        get root_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include('AKAdemy')
      end
    end
  end

  describe 'GET /home (student dashboard)' do
    context 'when user is not signed in' do
      it 'redirects to login' do
        get public_home_path
        expect(response).to redirect_to(student_login_path)
      end
    end

    context 'when user is signed in as student' do
      let(:student) do
        user = create(:user, school: school)
        UserRole.create!(user: user, role: student_role, school: school)
        school_class = SchoolClass.create!(
          school: school,
          name: '4A',
          year: '2025/2026',
          qr_token: SecureRandom.uuid,
          metadata: {}
        )
        StudentClassEnrollment.create!(
          student: user,
          school_class: school_class,
          status: 'approved'
        )
        user.reload
      end

      before { sign_in student }

      it 'renders student dashboard' do
        get public_home_path
        expect(response).to have_http_status(:success)
      end

      it 'loads student classes' do
        get public_home_path
        expect(response).to have_http_status(:success)
        # Student should see their classes - verify by checking response contains class name
        expect(response.body).to include('4A')
      end

      it 'loads student quiz results' do
        subject_record = create(:subject, school: school, title: 'Matematyka')
        unit = create(:unit, subject: subject_record)
        learning_module = create(:learning_module, unit: unit)
        create(:quiz_result, user: student, learning_module: learning_module, score: 85)

        get public_home_path
        expect(response).to have_http_status(:success)
        # Verify quiz results are loaded by checking subject name appears
        expect(response.body).to include('Matematyka')
      end
    end

    context 'when user is signed in as teacher (not a student)' do
      let(:teacher) do
        user = create(:user, school: school)
        UserRole.create!(user: user, role: teacher_role, school: school)
        user.reload
      end

      before { sign_in teacher }

      it 'redirects to login (requires student role)' do
        get public_home_path
        expect(response).to redirect_to(student_login_path)
      end
    end
  end
end
