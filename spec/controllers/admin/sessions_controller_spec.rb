# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::SessionsController, type: :request do
  let(:admin_role) { Role.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' } }
  let(:admin_user) do
    user = create(:user)
    UserRole.find_or_create_by!(user: user, role: admin_role) { |ur| ur.school = user.school }
    user
  end

  describe 'DELETE /admin/sign_out' do
    before do
      # Set up admin user with admin role
      admin_user # Ensure user is created

      # Create a valid JWT token
      token = Jwt::TokenService.encode({ user_id: admin_user.id })

      # Mock session and current_admin
      allow_any_instance_of(described_class).to receive(:session).and_return({ admin_id: token })
      allow_any_instance_of(described_class).to receive(:decode_jwt).with(token).and_return(admin_user)
      allow_any_instance_of(described_class).to receive(:current_admin).and_return(admin_user)
    end

    it 'logs logout event' do
      expect do
        delete destroy_admin_session_path
      end.to change(Event.where(event_type: 'user_logout'), :count).by(1)

      event = Event.where(event_type: 'user_logout').last
      expect(event.user).to eq(admin_user)
      expect(event.client).to eq('admin')
    end
  end
end
