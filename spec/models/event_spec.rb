# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Event, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:school).optional }
    it { is_expected.to belong_to(:user).optional }
  end

  describe 'columns' do
    it { is_expected.to have_db_column(:client) }
    it { is_expected.to have_db_column(:data) }
    it { is_expected.to have_db_column(:event_type) }
    it { is_expected.to have_db_column(:occurred_at) }
    it { is_expected.to have_db_column(:school_id) }
    it { is_expected.to have_db_column(:user_id) }
  end

  describe 'scopes' do
    let!(:user) { create(:user) }
    let!(:school) { user.school }
    let!(:old_test_event) do
      create(:event, user: user, school: school, event_type: 'test_event', occurred_at: 2.days.ago)
    end
    let!(:other_event) { create(:event, user: user, school: school, event_type: 'other_event', occurred_at: 1.day.ago) }
    let!(:recent_test_event) do
      create(:event, user: user, school: school, event_type: 'test_event', occurred_at: Time.current)
    end

    describe '.recent' do
      it 'orders by occurred_at desc, then created_at desc' do
        expect(described_class.recent.first).to eq(recent_test_event)
        expect(described_class.recent.last).to eq(old_test_event)
      end
    end

    describe '.by_type' do
      it 'filters by event_type' do
        expect(described_class.by_type('test_event')).to contain_exactly(old_test_event, recent_test_event)
        expect(described_class.by_type('other_event')).to contain_exactly(other_event)
      end
    end

    describe '.by_user' do
      let(:other_user) { create(:user) }
      let!(:other_user_event) { create(:event, user: other_user, school: other_user.school) }

      it 'filters by user' do
        expect(described_class.by_user(user)).to contain_exactly(old_test_event, other_event, recent_test_event)
        expect(described_class.by_user(other_user)).to contain_exactly(other_user_event)
      end
    end

    describe '.by_school' do
      let(:other_school) { create(:school) }
      let(:other_user) { create(:user, school: other_school) }
      let!(:other_school_event) { create(:event, user: other_user, school: other_school) }

      it 'filters by school' do
        expect(described_class.by_school(school)).to contain_exactly(old_test_event, other_event, recent_test_event)
        expect(described_class.by_school(other_school)).to contain_exactly(other_school_event)
      end
    end
  end
end
