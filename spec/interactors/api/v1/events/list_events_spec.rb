# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Events::ListEvents do
  let(:admin_role) { Role.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' } }
  let(:recent_event) { Event.find_by(event_type: 'login') }
  let(:user) { create(:user) }
  let(:admin) do
    UserRole.create!(user: user, role: admin_role, school: user.school)
    user
  end

  before do
    Event.create!(
      event_type: 'login',
      user: admin,
      occurred_at: Time.current,
      data: { info: 'recent' }
    )
    Event.create!(
      event_type: 'logout',
      user: admin,
      occurred_at: 3.days.ago,
      data: { info: 'old' }
    )
  end

  it 'requires admin access' do
    result = described_class.call(current_user: nil, params: {})

    expect(result).to be_failure
    expect(result.message).to include('Brak uprawnień')
  end

  it 'returns paginated events for admin users' do
    result = described_class.call(current_user: admin, params: { per_page: 1, page: 1 })

    expect(result).to be_success
    expect(result.form.length).to eq(1)
    expect(result.serializer).to eq(EventSerializer)
    expect(result.pagination[:total]).to eq(2)
  end

  it 'filters events by date range and search term' do
    params = {
      current_user: admin,
      params: {
        from: 2.days.ago.iso8601,
        search: 'login'
      }
    }

    result = described_class.call(params)

    expect(result.form).to contain_exactly(recent_event)
  end
end
