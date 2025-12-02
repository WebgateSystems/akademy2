# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventSerializer do
  subject(:serialized) { described_class.new(event).serializable_hash[:data][:attributes] }

  let(:user) do
    create(:user, first_name: 'Anna', last_name: 'Nowak', email: 'anna@example.com')
  end

  let(:event) do
    Event.create!(
      event_type: 'teacher_created',
      user: user,
      occurred_at: Time.current,
      data: {
        'subject_type' => 'Teacher',
        'subject_id' => '123',
        'subject_owner_id' => '999',
        'extra' => 'value'
      }
    )
  end

  it 'includes basic attributes' do
    expect(serialized[:event_type]).to eq('teacher_created')
    expect(serialized[:occurred_at]).to be_present
    expect(serialized[:data]).to include('extra' => 'value')
  end

  it 'builds user fields' do
    expect(serialized[:user_name]).to eq('Anna Nowak')
    expect(serialized[:user_email]).to eq('anna@example.com')
  end

  it 'falls back to email when name missing' do
    user.update!(first_name: nil, last_name: nil)

    expect(described_class.new(event).serializable_hash[:data][:attributes][:user_name])
      .to eq('anna@example.com')
  end

  it 'derives subject metadata from event data' do
    expect(serialized[:subject_type]).to eq('Teacher')
    expect(serialized[:subject_id]).to eq('123')
    expect(serialized[:subject_owner_id]).to eq('999')
  end

  it 'falls back to defaults when data missing' do
    event.update!(data: {})

    attributes = described_class.new(event).serializable_hash[:data][:attributes]
    expect(attributes[:subject_type]).to eq('teacher_created')
    expect(attributes[:subject_id]).to eq(event.id)
    expect(attributes[:subject_owner_id]).to be_nil
  end
end
