# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Units interactors' do
  let(:user) { create(:user) }
  let(:subject_record) { create(:subject, school: nil) }
  let!(:unit) { Unit.create!(subject: subject_record, title: 'Unit 1', order_index: 0) }

  describe Api::V1::Units::ListUnits do
    it 'returns units for authenticated users' do
      result = described_class.call(current_user: user, params: {})

      expect(result).to be_success
      expect(result.form).to include(unit)
      expect(result.serializer).to eq(UnitSerializer)
    end

    it 'filters by subject id' do
      result = described_class.call(current_user: user, params: { subject_id: subject_record.id })

      expect(result.form).to contain_exactly(unit)
    end
  end

  describe Api::V1::Units::ShowUnit do
    it 'returns the unit' do
      result = described_class.call(current_user: user, params: { id: unit.id })

      expect(result).to be_success
      expect(result.form).to eq(unit)
    end

    it 'fails when unit is missing' do
      result = described_class.call(current_user: user, params: { id: SecureRandom.uuid })

      expect(result).to be_failure
      expect(result.status).to eq(:not_found)
    end
  end
end
