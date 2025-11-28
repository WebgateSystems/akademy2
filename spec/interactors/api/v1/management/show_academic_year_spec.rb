# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Management::ShowAcademicYear do
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
            id: academic_year.id
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

      it 'returns academic year' do
        result = described_class.call(context)
        expect(result.form).to eq(academic_year)
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
            id: academic_year.id
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
            id: SecureRandom.uuid
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

    context 'when academic year belongs to different school' do
      let(:other_school) { create(:school) }
      let(:other_academic_year) do
        AcademicYear.create!(school: other_school, year: '2024/2025', is_current: false)
      end
      let(:context) do
        {
          current_user: school_manager,
          params: {
            id: other_academic_year.id
          }
        }
      end

      before do
        principal_role
        school_manager_role
        school_manager
        other_academic_year
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
  end
end
