# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::DashboardController, type: :controller do
  let(:admin_role) { Role.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' } }
  let(:admin) do
    user = create(:user)
    UserRole.create!(user: user, role: admin_role)
    user
  end

  def login_as_admin(user)
    token = Jwt::TokenService.encode({ user_id: user.id })
    session[:admin_id] = token
  end

  before { login_as_admin(admin) }

  describe 'GET #index' do
    it 'returns http success' do
      login_as_admin(admin)
      get :index
      expect(response).to have_http_status(:success)
    end

    it 'loads schools count' do
      baseline = School.count
      create_list(:school, 3)
      login_as_admin(admin)
      get :index
      expect(assigns(:schools_count)).to eq(baseline + 3)
    end

    it 'loads headmasters count' do
      principal_role = Role.find_or_create_by!(key: 'principal') { |r| r.name = 'Principal' }
      school = create(:school)
      headmaster = create(:user, school: school)
      UserRole.create!(user: headmaster, role: principal_role, school: school)

      login_as_admin(admin)
      get :index
      expect(assigns(:headmasters_count)).to eq(1)
    end

    it 'loads teachers count' do
      teacher_role = Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' }
      school = create(:school)
      teacher = create(:user, school: school)
      UserRole.create!(user: teacher, role: teacher_role, school: school)

      login_as_admin(admin)
      get :index
      expect(assigns(:teachers_count)).to eq(1)
    end

    it 'loads pupils count' do
      student_role = Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' }
      school = create(:school)
      student = create(:user, school: school)
      UserRole.create!(user: student, role: student_role, school: school)

      login_as_admin(admin)
      get :index
      expect(assigns(:pupils_count)).to eq(1)
    end

    it 'loads activity log statistics' do
      create(:event, event_type: 'user_login', user: admin)
      create(:event, event_type: 'video_view', user: admin)
      create(:event, event_type: 'quiz_complete', user: admin)

      login_as_admin(admin)
      get :index
      expect(assigns(:logins_count)).to eq(1)
      expect(assigns(:videos_viewed_count)).to eq(1)
      expect(assigns(:quizzes_completed_count)).to eq(1)
    end

    it 'loads top schools' do
      create_list(:school, 10)
      get :index
      expect(assigns(:top_schools).count).to eq(5)
    end
  end
end
