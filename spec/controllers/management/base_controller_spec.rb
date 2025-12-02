# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Management::BaseController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:principal_role) { Role.find_or_create_by!(key: 'principal') { |r| r.name = 'Principal' } }
  let(:school_manager_role) { Role.find_or_create_by!(key: 'school_manager') { |r| r.name = 'School Manager' } }
  let(:teacher_role) { Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }
  let(:school) { create(:school) }

  before do
    principal_role
    school_manager_role
    teacher_role
    Rails.application.routes.default_url_options[:host] ||= 'example.com'
  end

  describe '#require_school_management_access!' do
    context 'when user has no management roles' do
      let(:non_manager) do
        user = create(:user, school: school)
        UserRole.create!(user: user, role: teacher_role, school: school)
        user.reload
      end

      before { sign_in non_manager }

      it 'redirects to login page with alert to avoid redirect loop' do
        get management_root_path

        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to include('Brak uprawnień do zarządzania szkołą')
        expect(flash[:alert]).to include('Zaloguj się ponownie')
      end
    end

    context 'when user has principal role' do
      let(:principal) do
        user = create(:user, school: school)
        UserRole.create!(user: user, role: principal_role, school: school)
        user.reload
      end

      before { sign_in principal }

      it 'allows access' do
        get management_root_path
        expect(response).to have_http_status(:success)
      end
    end

    context 'when user has school_manager role' do
      let(:manager) do
        user = create(:user, school: school)
        UserRole.create!(user: user, role: school_manager_role, school: school)
        user.reload
      end

      before { sign_in manager }

      it 'allows access' do
        get management_root_path
        expect(response).to have_http_status(:success)
      end
    end
  end
end
