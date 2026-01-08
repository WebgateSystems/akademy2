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
    # Настраиваем аутентификацию
    allow(controller).to receive_messages(current_admin: admin_user, authenticate_admin!: true, require_admin!: true,
                                          check_admin_active!: true)
    allow_any_instance_of(ActionView::Helpers::AssetTagHelper).to receive(:stylesheet_link_tag).and_return('')
    allow_any_instance_of(ActionView::Helpers::AssetTagHelper).to receive(:javascript_include_tag).and_return('')
    allow_any_instance_of(ActionView::Helpers::AssetTagHelper).to receive(:image_tag).and_return('')
  end

  describe 'GET #index' do
    let!(:ip_rule) { RequestBlockRule.create!(rule_type: 'ip', value: '192.168.1.1', note: 'Bad IP') }
    let!(:user_victim) { create(:user, email: 'victim@example.com', first_name: 'John', last_name: 'Doe') }
    let!(:user_rule) { RequestBlockRule.create!(rule_type: 'user', value: user_victim.id.to_s) }

    it 'returns a successful response' do
      get :index
      expect(response).to be_successful
      expect(assigns(:rules)).to include(ip_rule, user_rule)
    end

    it 'filters rules by note' do
      get :index, params: { q: 'Bad' }
      expect(assigns(:rules)).to include(ip_rule)
      expect(assigns(:rules)).not_to include(user_rule)
    end

    it 'filters rules by user information (email)' do
      get :index, params: { q: 'victim@example.com' }
      expect(assigns(:rules)).to include(user_rule)
      expect(assigns(:rules)).not_to include(ip_rule)
    end

    it 'filters rules by user full name' do
      get :index, params: { q: 'John Doe' }
      expect(assigns(:rules)).to include(user_rule)
    end

    it 'correctly populates @blocked_users_by_id' do
      get :index
      expect(assigns(:blocked_users_by_id)).to have_key(user_victim.id.to_s)
      expect(assigns(:blocked_users_by_id)[user_victim.id.to_s]).to eq(user_victim)
    end
  end

  describe 'DELETE #destroy' do
    context 'when rule is for a user' do
      let!(:victim) { create(:user, locked_at: Time.current) }
      let!(:rule) { RequestBlockRule.create!(rule_type: 'user', value: victim.id.to_s) }

      it 'deletes the rule and unlocks the user' do
        expect do
          delete :destroy, params: { id: rule.id }
        end.to change(RequestBlockRule, :count).by(-1)

        expect(victim.reload.locked_at).to be_nil
        expect(flash[:notice]).to eq('Usunięto regułę i odblokowano konto użytkownika.')
        expect(response).to redirect_to(admin_request_block_rules_path)
      end

      it 'returns success via JSON' do
        delete :destroy, params: { id: rule.id }, format: :json
        json = JSON.parse(response.body)
        expect(json['ok']).to be true
        expect(json['unlocked']).to be true
      end
    end

    context 'when rule is for an IP' do
      let!(:rule) { RequestBlockRule.create!(rule_type: 'ip', value: '1.2.3.4') }

      it 'deletes the rule without unlocking anyone' do
        delete :destroy, params: { id: rule.id }
        expect(RequestBlockRule.find_by(id: rule.id)).to be_nil
        expect(flash[:notice]).to eq('Usunięto regułę.')
      end
    end

    context 'when rule does not exist' do
      it 'redirects to index with an alert' do
        delete :destroy, params: { id: 999_999 }
        expect(response).to redirect_to(admin_request_block_rules_path)
        expect(flash[:alert]).to eq('Nie znaleziono reguły.')
      end

      it 'returns 404 via JSON' do
        delete :destroy, params: { id: 999_999 }, format: :json
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
