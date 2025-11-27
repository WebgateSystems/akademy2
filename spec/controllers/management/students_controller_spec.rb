# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Management::StudentsController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:principal_role) { Role.find_or_create_by!(key: 'principal') { |r| r.name = 'Principal' } }
  let(:school_manager_role) { Role.find_or_create_by!(key: 'school_manager') { |r| r.name = 'School Manager' } }

  let(:school) { create(:school) }
  let(:principal) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: principal_role, school: school)
    user.reload
    user
  end

  before do
    principal_role
    school_manager_role
    sign_in principal
    principal.roles.load if principal.roles.loaded? == false
  end

  describe 'GET #index' do
    it 'returns http success' do
      get management_students_path
      expect(response).to have_http_status(:success)
    end

    it 'assigns school' do
      get management_students_path
      # Verify redirect doesn't happen (school is assigned)
      expect(response).to have_http_status(:success)
      # School should be assigned (no redirect means school exists)
      expect(response).not_to redirect_to(management_root_path)
    end

    it 'assigns school classes' do
      SchoolClass.create!(
        school: school,
        name: '4A',
        year: '2025/2026',
        qr_token: SecureRandom.uuid,
        metadata: {}
      )
      get management_students_path
      # Check that school classes are accessible in the view
      expect(response.body).to include('4A')
      expect(response).to have_http_status(:success)
    end

    context 'when user has no school' do
      before do
        principal.update!(school: nil)
      end

      it 'redirects to management root' do
        get management_students_path
        expect(response).to redirect_to(management_root_path)
      end
    end
  end
end
