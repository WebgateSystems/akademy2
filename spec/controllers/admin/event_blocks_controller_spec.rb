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

  let(:victim) { create(:user, confirmed_at: Time.current) }
  let(:event) { create(:event, user: victim, data: { ip: '1.2.3.4' }) }

  before do
    allow(controller).to receive_messages(current_admin: admin_user, authenticate_admin!: true, require_admin!: true,
                                          check_admin_active!: true)
  end

  describe 'POST #preview' do
    it 'returns rule data for valid kind' do
      post :preview, params: { id: event.id, kind: 'user' }, format: :json

      expect(response).to be_successful
      json = JSON.parse(response.body)
      expect(json['ok']).to be true
      expect(json['rule_type']).to eq('user')
      expect(json['value']).to eq(victim.id.to_s)
    end

    it 'returns error when builder returns error message' do
      # Эмулируем ошибку из билдера (например, если IP отсутствует)
      allow_any_instance_of(Admin::EventBlockRuleBuilder).to receive(:call).and_return({ error: 'Some error' })

      post :preview, params: { id: event.id, kind: 'ip' }, format: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['error']).to eq('Some error')
    end
  end

  describe 'POST #create' do
    context 'when kind is user' do
      it 'creates rule and locks the user' do
        expect do
          post :create, params: { id: event.id, kind: 'user' }, format: :json
        end.to change(RequestBlockRule, :count).by(1)

        expect(response).to be_successful
        expect(victim.reload.locked_at).to be_present

        rule = RequestBlockRule.last
        expect(rule.rule_type).to eq('user')
        expect(rule.created_by).to eq(admin_user)
      end

      it 'handles existing rules (RecordNotUnique)' do
        # Создаем правило заранее
        RequestBlockRule.create!(rule_type: 'user', value: victim.id.to_s)

        post :create, params: { id: event.id, kind: 'user' }, format: :json

        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json['duplicated']).to be true
      end
    end

    context 'when kind is ip' do
      it 'creates IP block rule but does not lock user' do
        post :create, params: { id: event.id, kind: 'ip' }, format: :json

        expect(response).to be_successful
        expect(victim.reload.locked_at).to be_nil
        expect(RequestBlockRule.where(rule_type: 'ip')).to exist
      end
    end

    context 'when error handling' do
      it 'returns 404 for non-existent event' do
        post :create, params: { id: 0, kind: 'user' }, format: :json
        expect(response).to have_http_status(:not_found)
      end

      it 'returns 422 for invalid kind' do
        # Если билдер вернет nil
        allow_any_instance_of(Admin::EventBlockRuleBuilder).to receive(:call).and_return(nil)

        post :create, params: { id: event.id, kind: 'unknown' }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to eq('Nieprawidłowy typ blokady.')
      end
    end
  end
end
