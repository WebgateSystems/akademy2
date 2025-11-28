# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Management::UpdateAcademicYear do
  let(:principal_role) { Role.find_or_create_by!(key: 'principal') { |r| r.name = 'Principal' } }
  let(:school_manager_role) { Role.find_or_create_by!(key: 'school_manager') { |r| r.name = 'School Manager' } }

  let(:school) { create(:school) }
  let(:school_manager) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: school_manager_role, school: school)
    user
  end
  let(:academic_year) do
    AcademicYear.create!(school: school, year: '2024/2025', is_current: false)
  end

  describe '#call' do
    context 'when user is authorized' do
      let(:context) do
        {
          current_user: school_manager,
          params: {
            id: academic_year.id,
            academic_year: {
              year: '2025/2026',
              is_current: true
            }
          }
        }
      end

      before do
        principal_role
        school_manager_role
        school_manager
        academic_year
      end

      it 'succeeds' do
        result = described_class.call(context)
        expect(result).to be_success
      end

      it 'updates year' do
        described_class.call(context)
        expect(academic_year.reload.year).to eq('2025/2026')
      end

      it 'updates is_current' do
        described_class.call(context)
        expect(academic_year.reload.is_current).to be true
      end

      it 'auto-calculates started_at from year' do
        described_class.call(context)
        expect(academic_year.reload.started_at).to eq(Date.new(2025, 9, 1))
      end

      it 'unsets other current years when setting new current year' do
        existing_current = AcademicYear.create!(school: school, year: '2023/2024', is_current: true)
        described_class.call(context)
        expect(existing_current.reload.is_current).to be false
        expect(academic_year.reload.is_current).to be true
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
          params: {
            id: academic_year.id,
            academic_year: {
              year: '2025/2026',
              is_current: false
            }
          }
        }
      end

      before do
        academic_year
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

    context 'when academic year not found' do
      let(:context) do
        {
          current_user: school_manager,
          params: {
            id: SecureRandom.uuid,
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

      it 'fails' do
        result = described_class.call(context)
        expect(result).not_to be_success
      end

      it 'returns not found status' do
        result = described_class.call(context)
        expect(result.status).to eq(:not_found)
      end

      it 'returns error message' do
        result = described_class.call(context)
        expect(result.message).to be_an(Array)
        expect(result.message.any? { |m| m.include?('nie został znaleziony') }).to be true
      end
    end

    context 'when year is invalid' do
      let(:context) do
        {
          current_user: school_manager,
          params: {
            id: academic_year.id,
            academic_year: {
              year: '2025/2028',
              is_current: false
            }
          }
        }
      end

      before do
        principal_role
        school_manager_role
        school_manager
        academic_year
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
  end
end
