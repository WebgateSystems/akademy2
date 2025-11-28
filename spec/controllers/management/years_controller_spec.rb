# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Management::YearsController, type: :request do
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
    # rubocop:disable RSpec/LetSetup, RSpec/IndexedLet, Naming/VariableNumber
    let!(:year_2023) { AcademicYear.create!(school: school, year: '2023/2024', is_current: false) }
    let!(:year_2024) { AcademicYear.create!(school: school, year: '2024/2025', is_current: false) }
    let!(:year_2025) { AcademicYear.create!(school: school, year: '2025/2026', is_current: true) }
    # rubocop:enable RSpec/LetSetup, RSpec/IndexedLet, Naming/VariableNumber

    it 'returns http success' do
      get management_years_path
      expect(response).to have_http_status(:success)
    end

    it 'displays academic years' do
      get management_years_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('2023/2024')
      expect(response.body).to include('2024/2025')
      expect(response.body).to include('2025/2026')
    end

    it 'displays academic years ordered by start year ascending' do
      get management_years_path
      expect(response).to have_http_status(:success)
      # Check that years appear in order in the HTML
      body = response.body
      # rubocop:disable Naming/VariableNumber
      pos_year_2023 = body.index('2023/2024')
      pos_year_2024 = body.index('2024/2025')
      pos_year_2025 = body.index('2025/2026')
      # rubocop:enable Naming/VariableNumber
      expect(pos_year_2023).to be < pos_year_2024
      expect(pos_year_2024).to be < pos_year_2025
    end

    it 'displays current academic year' do
      get management_years_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('2025/2026')
      expect(response.body).to include('Current')
    end

    context 'when user has no school' do
      before do
        principal.update!(school: nil)
      end

      it 'redirects to management root' do
        get management_years_path
        expect(response).to redirect_to(management_root_path)
      end
    end
  end
end
