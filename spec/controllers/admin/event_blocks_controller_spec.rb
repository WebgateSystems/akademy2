# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::EventBlocksController, type: :controller do
  render_views

  let!(:admin_role) { Role.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' } }
  let(:admin_user) do
    u = create(:user, confirmed_at: Time.current)
    UserRole.create!(user: u, role: admin_role)
    u
  end

  before do
    allow_any_instance_of(Admin::BaseController).to receive(:current_admin).and_return(admin_user)
    allow_any_instance_of(Admin::BaseController).to receive(:authenticate_admin!).and_return(true)
    allow_any_instance_of(Admin::BaseController).to receive(:require_admin!).and_return(true)
    allow_any_instance_of(Admin::BaseController).to receive(:check_admin_active!).and_return(true)
  end

  describe 'POST #create (kind=user)' do
    it 'creates user block rule and locks the user via Devise' do
      victim = create(:user, confirmed_at: Time.current)
      event = Event.create!(
        event_type: 'api_request',
        user: victim,
        occurred_at: Time.current,
        data: { ip: '1.2.3.4' },
        client: 'api'
      )

      post :create, params: { id: event.id, kind: 'user' }, as: :json

      expect(response).to have_http_status(:ok)
      expect(RequestBlockRule.where(rule_type: 'user', value: victim.id.to_s)).to exist
      expect(victim.reload.locked_at).to be_present
    end
  end
end
