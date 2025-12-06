# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Plan, type: :model do
  describe 'factory' do
    it 'creates valid plan' do
      plan = described_class.create!(key: 'test_plan', name: 'Test Plan')
      expect(plan).to be_persisted
      expect(plan.key).to eq('test_plan')
    end
  end

  describe 'database constraints' do
    it 'raises error when key is missing' do
      expect do
        described_class.create!(name: 'Test')
      end.to raise_error(ActiveRecord::NotNullViolation)
    end

    it 'raises error when key is not unique' do
      described_class.create!(key: 'unique_plan', name: 'Plan 1')
      expect do
        described_class.create!(key: 'unique_plan', name: 'Plan 2')
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
