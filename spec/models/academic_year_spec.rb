# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AcademicYear, type: :model do
  let(:school) { create(:school) }

  describe 'associations' do
    it { is_expected.to belong_to(:school) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:year) }
    it { is_expected.to validate_presence_of(:school_id) }

    it 'validates uniqueness of year scoped to school_id' do
      described_class.create!(school: school, year: '2025/2026', is_current: false)
      duplicate = described_class.new(school: school, year: '2025/2026', is_current: false)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:year]).to include('has already been taken')
    end

    context 'when year format is invalid' do
      it 'rejects non-consecutive years' do
        academic_year = described_class.new(school: school, year: '2025/2028', is_current: false)
        expect(academic_year).not_to be_valid
        expect(academic_year.errors[:year]).to include('musi składać się z dwóch kolejnych lat (np. 2025/2026)')
      end

      it 'rejects reversed years' do
        academic_year = described_class.new(school: school, year: '2026/2025', is_current: false)
        expect(academic_year).not_to be_valid
        expect(academic_year.errors[:year]).to include('musi składać się z dwóch kolejnych lat (np. 2025/2026)')
      end

      it 'rejects invalid format' do
        academic_year = described_class.new(school: school, year: '2025-2026', is_current: false)
        expect(academic_year).not_to be_valid
        expect(academic_year.errors[:year]).to include('ma nieprawidłowy format (oczekiwany format: YYYY/YYYY)')
      end

      it 'rejects empty year' do
        academic_year = described_class.new(school: school, year: '', is_current: false)
        expect(academic_year).not_to be_valid
        expect(academic_year.errors[:year]).to include("can't be blank")
      end
    end

    context 'when year format is valid' do
      it 'accepts consecutive years' do
        academic_year = described_class.new(school: school, year: '2025/2026', is_current: false)
        expect(academic_year).to be_valid
      end

      it 'accepts another valid year' do
        academic_year = described_class.new(school: school, year: '2024/2025', is_current: false)
        expect(academic_year).to be_valid
      end
    end

    context 'when year is not unique per school' do
      before do
        described_class.create!(school: school, year: '2025/2026', is_current: false)
      end

      it 'rejects duplicate year for same school' do
        academic_year = described_class.new(school: school, year: '2025/2026', is_current: false)
        expect(academic_year).not_to be_valid
        expect(academic_year.errors[:year]).to include('has already been taken')
      end

      it 'allows same year for different school' do
        other_school = create(:school)
        academic_year = described_class.new(school: other_school, year: '2025/2026', is_current: false)
        expect(academic_year).to be_valid
      end
    end
  end

  describe 'scopes' do
    let!(:current_year) do
      described_class.create!(school: school, year: '2025/2026', is_current: true)
    end
    let!(:archived_year) do
      described_class.create!(school: school, year: '2024/2025', is_current: false)
    end
    let!(:another_archived_year) do
      described_class.create!(school: school, year: '2023/2024', is_current: false)
    end

    describe '.current' do
      it 'returns only current academic year' do
        expect(described_class.current).to contain_exactly(current_year)
      end
    end

    describe '.for_school' do
      let(:other_school) { create(:school) }
      # rubocop:disable RSpec/LetSetup
      let!(:other_school_year) do
        described_class.create!(school: other_school, year: '2025/2026', is_current: false)
      end
      # rubocop:enable RSpec/LetSetup

      it 'returns only academic years for given school' do
        expect(described_class.for_school(school)).to contain_exactly(
          current_year, archived_year, another_archived_year
        )
      end
    end

    describe '.ordered' do
      it 'returns academic years ordered by start year ascending' do
        expect(described_class.ordered.pluck(:year)).to eq(['2023/2024', '2024/2025', '2025/2026'])
      end
    end
  end

  describe 'callbacks' do
    describe 'before_save :ensure_single_current_year' do
      let!(:existing_current_year) do
        described_class.create!(school: school, year: '2024/2025', is_current: true)
      end

      it 'unsets other current years when setting new current year' do
        new_current_year = described_class.create!(school: school, year: '2025/2026', is_current: true)
        expect(new_current_year).to be_persisted
        expect(new_current_year.reload.is_current).to be true
        expect(existing_current_year.reload.is_current).to be false
      end

      it 'does not affect current year of other schools' do
        other_school = create(:school)
        other_current_year = described_class.create!(school: other_school, year: '2025/2026', is_current: true)
        expect(other_current_year.reload.is_current).to be true
        expect(existing_current_year.reload.is_current).to be true
      end
    end
  end
end
