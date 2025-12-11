# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Student Dashboard', type: :request do
  let(:student_role) { Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' } }
  let(:school) { create(:school) }
  let(:school_class) { create(:school_class, school: school) }
  let(:student) { create(:user, school: school) }
  let(:student_without_enrollment) { create(:user) }

  before do
    UserRole.create!(user: student, role: student_role, school: school)
    StudentClassEnrollment.create!(
      student: student,
      school_class: school_class,
      status: 'approved'
    )
  end

  describe 'GET /home' do
    context 'when student has approved enrollment' do
      before do
        sign_in(student)
      end

      it 'shows School videos link in sidebar' do
        get public_home_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('School videos')
      end
    end

    context 'when student has no approved enrollment' do
      before do
        UserRole.create!(user: student_without_enrollment, role: student_role, school: nil)
        sign_in(student_without_enrollment)
      end

      it 'does not show School videos link in sidebar' do
        get public_home_path
        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include('School videos')
      end
    end
  end

  describe 'GET /student/videos' do
    context 'when student has approved enrollment' do
      before do
        sign_in(student)
      end

      it 'allows access' do
        get student_videos_path
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when student has no approved enrollment' do
      before do
        UserRole.create!(user: student_without_enrollment, role: student_role, school: nil)
        sign_in(student_without_enrollment)
      end

      it 'redirects to dashboard with alert' do
        get student_videos_path
        expect(response).to redirect_to(public_home_path)
        expect(flash[:alert]).to include('Musisz być przypisany do klasy')
      end
    end
  end
end
