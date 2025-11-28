# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Management::ListAcademicYears do
  let(:principal_role) { Role.find_or_create_by!(key: 'principal') { |r| r.name = 'Principal' } }
  let(:school_manager_role) { Role.find_or_create_by!(key: 'school_manager') { |r| r.name = 'School Manager' } }

  let(:school) { create(:school) }
  let(:school_manager) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: school_manager_role, school: school)
    user
  end

  describe '#call' do
    context 'when user is authorized' do
      # rubocop:disable RSpec/IndexedLet, Naming/VariableNumber
      let!(:year_2023) { AcademicYear.create!(school: school, year: '2023/2024', is_current: false) }
      let!(:year_2024) { AcademicYear.create!(school: school, year: '2024/2025', is_current: false) }
      let!(:year_2025) { AcademicYear.create!(school: school, year: '2025/2026', is_current: true) }
      # rubocop:enable RSpec/IndexedLet, Naming/VariableNumber

      let(:context) do
        {
          current_user: school_manager,
          params: {}
        }
      end

      before do
        principal_role
        school_manager_role
        school_manager
      end

      it 'succeeds' do
        result = described_class.call(context)
        expect(result).to be_success
      end

      it 'returns all academic years for school' do
        result = described_class.call(context)
        expect(result.form).to contain_exactly(year_2023, year_2024, year_2025)
      end

      it 'returns academic years ordered by start year ascending' do
        result = described_class.call(context)
        expect(result.form.pluck(:year)).to eq(['2023/2024', '2024/2025', '2025/2026'])
      end

      it 'does not return academic years from other schools' do
        other_school = create(:school)
        other_year = AcademicYear.create!(school: other_school, year: '2025/2026', is_current: false)
        result = described_class.call(context)
        expect(result.form).not_to include(other_year)
      end

      it 'sets status to ok' do
        result = described_class.call(context)
        expect(result.status).to eq(:ok)
      end

      it 'sets serializer' do
        result = described_class.call(context)
        expect(result.serializer).to eq(AcademicYearSerializer)
      end
    end

    context 'when user is not authorized' do
      let(:unauthorized_user) { create(:user) }
      let(:context) do
        {
          current_user: unauthorized_user,
          params: {}
        }
      end

      it 'fails' do
        result = described_class.call(context)
        expect(result).not_to be_success
      end

      it 'returns error message' do
        result = described_class.call(context)
        expect(result.message).to include('Brak uprawnień')
      end
    end

    context 'when user has no school' do
      let(:other_school) { create(:school) }
      let(:user_without_school) do
        user = create(:user, school: nil)
        # UserRole requires school, so we'll test with a user that has a role but no direct school assignment
        UserRole.create!(user: user, role: school_manager_role, school: other_school)
        user.update!(school: nil)
        # Remove the user_role to simulate no school access
        UserRole.where(user: user).destroy_all
        user
      end
      let(:context) do
        {
          current_user: user_without_school,
          params: {}
        }
      end

      before do
        principal_role
        school_manager_role
      end

      it 'fails' do
        result = described_class.call(context)
        expect(result).not_to be_success
      end

      it 'returns error message' do
        result = described_class.call(context)
        # User without school management role will fail authorization first
        expect(result.message).to be_an(Array)
        expect(result.message.any? { |m| m.include?('uprawnień') || m.include?('szkoły') }).to be true
      end
    end
  end
end
