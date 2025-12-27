# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::RequestBlockRulesController, type: :controller do
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

  describe 'DELETE #destroy' do
    it 'unlocks devise lock when deleting user block rule' do
      victim = create(:user, confirmed_at: Time.current)
      victim.lock_access!
      rule = RequestBlockRule.create!(rule_type: 'user', value: victim.id, created_by: admin_user)

      delete :destroy, params: { id: rule.id }

      expect(response).to have_http_status(:redirect)
      expect(RequestBlockRule.find_by(id: rule.id)).to be_nil
      expect(victim.reload.locked_at).to be_nil
    end
  end
end
