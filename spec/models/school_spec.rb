# frozen_string_literal: true

require 'rails_helper'

RSpec.describe School, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:academic_years).dependent(:destroy) }
    it { is_expected.to have_many(:school_classes).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:school) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:city) }
    it { is_expected.to validate_presence_of(:country) }
    it { is_expected.to validate_uniqueness_of(:slug) }
  end

  describe '#school_classes' do
    let(:school) { create(:school) }

    it 'returns school classes belonging to the school' do
      class_a = create(:school_class, school: school, name: '1A')
      class_b = create(:school_class, school: school, name: '2B')
      other_school = create(:school)
      create(:school_class, school: other_school, name: '3C')

      expect(school.school_classes).to contain_exactly(class_a, class_b)
    end

    it 'destroys school classes when school is destroyed' do
      create(:school_class, school: school, name: '1A')
      create(:school_class, school: school, name: '2B')

      expect { school.destroy }.to change(SchoolClass, :count).by(-2)
    end
  end
end
