# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Subscription, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:school) }
    it { is_expected.to belong_to(:plan) }
  end

  describe 'factory' do
    let(:school) { create(:school) }
    let(:plan) { Plan.create!(key: "plan_#{SecureRandom.hex(4)}", name: 'Test Plan') }

    it 'creates valid subscription' do
      subscription = described_class.create!(
        school: school,
        plan: plan,
        starts_on: Date.current,
        expires_on: 1.year.from_now.to_date,
        status: 'active'
      )
      expect(subscription).to be_persisted
      expect(subscription.school).to eq(school)
      expect(subscription.plan).to eq(plan)
      expect(subscription.status).to eq('active')
    end
  end
end
