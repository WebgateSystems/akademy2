# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Management::CreateAcademicYear do
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
      let(:context) do
        {
          current_user: school_manager,
          params: {
            academic_year: {
              year: '2025/2026',
              is_current: false
            }
          }
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

      it 'creates academic year' do
        expect do
          described_class.call(context)
        end.to change(AcademicYear, :count).by(1)
      end

      it 'assigns academic year to school' do
        result = described_class.call(context)
        academic_year = result.form
        expect(academic_year.school_id).to eq(school.id)
      end

      it 'sets correct year' do
        result = described_class.call(context)
        academic_year = result.form
        expect(academic_year.year).to eq('2025/2026')
      end

      it 'auto-calculates started_at from year' do
        result = described_class.call(context)
        academic_year = result.form
        expect(academic_year.started_at).to eq(Date.new(2025, 9, 1))
      end

      it 'sets is_current correctly' do
        result = described_class.call(context)
        academic_year = result.form
        expect(academic_year.is_current).to be false
      end

      it 'sets is_current to true when provided' do
        context[:params] = {
          academic_year: {
            year: '2025/2026',
            is_current: true
          }
        }
        result = described_class.call(context)
        academic_year = result.form
        expect(academic_year.is_current).to be true
      end

      it 'unsets other current years when setting new current year' do
        existing_current = AcademicYear.create!(school: school, year: '2024/2025', is_current: true)
        context[:params] = {
          academic_year: {
            year: '2025/2026',
            is_current: true
          }
        }
        result = described_class.call(context)
        expect(result).to be_success
        expect(existing_current.reload.is_current).to be false
      end

      it 'sets status to created' do
        result = described_class.call(context)
        expect(result.status).to eq(:created)
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
          params: ActionController::Parameters.new(
            academic_year: {
              year: '2025/2026',
              is_current: false
            }
          )
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
        # UserRole requires school, but we'll create it with a different school
        # and then remove all user_roles to simulate no school access
        UserRole.create!(user: user, role: school_manager_role, school: other_school)
        # Remove all user_roles to simulate user with no school management access
        UserRole.where(user: user).destroy_all
        user.reload
        user
      end
      let(:context) do
        {
          current_user: user_without_school,
          params: {
            academic_year: {
              year: '2025/2026',
              is_current: false
            }
          }
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

    context 'when year is invalid' do
      let(:context) do
        {
          current_user: school_manager,
          params: ActionController::Parameters.new(
            academic_year: {
              year: '2025/2028',
              is_current: false
            }
          )
        }
      end

      before do
        principal_role
        school_manager_role
        school_manager
      end

      it 'fails' do
        result = described_class.call(context)
        expect(result).not_to be_success
      end

      it 'returns validation error' do
        result = described_class.call(context)
        expect(result.message).to be_an(Array)
        expect(result.message.any? { |m| m.include?('kolejnych lat') }).to be true
      end
    end

    context 'when year already exists' do
      before do
        principal_role
        school_manager_role
        school_manager
        AcademicYear.create!(school: school, year: '2025/2026', is_current: false)
      end

      let(:context) do
        {
          current_user: school_manager,
          params: {
            academic_year: {
              year: '2025/2026',
              is_current: false
            }
          }
        }
      end

      it 'fails' do
        result = described_class.call(context)
        expect(result).not_to be_success
      end

      it 'returns uniqueness error' do
        result = described_class.call(context)
        expect(result.message).to be_an(Array)
        expect(result.message.any? { |m| m.include?('taken') }).to be true
      end
    end
  end
end
